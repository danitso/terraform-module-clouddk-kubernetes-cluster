#===============================================================================
# STEP 1: Install software
#===============================================================================
resource "null_resource" "kubernetes_install" {
  count      = length(clouddk_server.node)
  depends_on = ["clouddk_server.node"]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.node[count.index].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.private_ssh_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; done",
      "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done",
      "curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -",
      "echo 'deb http://apt.kubernetes.io kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "apt-key fingerprint 0EBFCD88",
      "add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable'",
      "apt-get -q update",
      "apt-get -q install -y docker-ce=5:18.09.8~3-0~ubuntu-xenial docker-ce-cli=5:18.09.8~3-0~ubuntu-xenial containerd.io kubelet kubeadm kubectl",
    ]
  }

  provisioner "file" {
    destination = "/etc/docker/daemon.json"
    content     = <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-file": "2",
    "max-size": "64m"
  },
  "storage-driver": "overlay2"
}
EOF
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/systemd/system/docker.service.d",
      "systemctl daemon-reload",
      "systemctl restart docker",
    ]
  }
}
#===============================================================================
# STEP 2: Generate control plane port numbers and CA certificate
#===============================================================================
resource "random_shuffle" "api_ports" {
  count        = "${var.master ? 1 : 0}"
  input        = ["6443"]
  result_count = length(clouddk_server.load_balancer)
}

resource "random_shuffle" "control_plane_ports" {
  count        = "${var.master ? 1 : 0}"
  input        = ["6443"]
  result_count = length(clouddk_server.node)
}

resource "tls_private_key" "ca_private_key" {
  count = "${var.master ? 1 : 0}"

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca_certificate" {
  count = "${var.master ? 1 : 0}"

  is_ca_certificate     = true
  key_algorithm         = "RSA"
  private_key_pem       = element(concat(tls_private_key.ca_private_key.*.private_key_pem, list("")), 0)
  validity_period_hours = 175320

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
    "key_agreement",
    "key_encipherment",
    "ocsp_signing",
    "server_auth",
    "client_auth",
  ]

  subject {
    common_name         = "Kubernetes"
    country             = "DK"
    organization        = "Danitso"
    organizational_unit = "Kubernetes"
    locality            = "Copenhagen"
  }
}
#===============================================================================
# STEP 3: Initialize cluster
#===============================================================================
resource "null_resource" "kubernetes_init" {
  count      = "${var.master ? 1 : 0}"
  depends_on = ["null_resource.kubernetes_install", "null_resource.load_balancer_configuration"]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.node[0].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.private_ssh_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/lib/kubelet/pki",
      "mkdir -p /etc/kubernetes/pki",
    ]
  }

  provisioner "file" {
    content     = element(concat(tls_private_key.ca_private_key.*.private_key_pem, list("")), 0)
    destination = "/etc/kubernetes/pki/ca.key"
  }

  provisioner "file" {
    content     = element(concat(tls_self_signed_cert.ca_certificate.*.cert_pem, list("")), 0)
    destination = "/etc/kubernetes/pki/ca.crt"
  }

  provisioner "file" {
    destination = "/tmp/config.new.yaml"
    content     = <<EOT
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- token: "${local.kubernetes_bootstrap_token}"
  description: "Default kubeadm bootstrap token"
  ttl: "0"
localAPIEndpoint:
  advertiseAddress: ${element(flatten(clouddk_server.node[0].network_interface_addresses), 0)}
  bindPort: 6443
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: "external"
    container-log-max-files: "2"
    container-log-max-size: "64Mi"
    node-ip: "${element(flatten(clouddk_server.node[0].network_interface_addresses), 0)}"
    node-labels: "kubernetes.cloud.dk/node-pool=${var.node_pool_name}"
certificateKey: "${local.kubernetes_certificate_key}"
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: stable
clusterName: ${var.cluster_name}
controlPlaneEndpoint: ${element(local.kubernetes_api_addresses, 0)}:${element(local.kubernetes_api_ports, 0)}
certificatesDir: /etc/kubernetes/pki
networking:
  podSubnet: 10.32.0.0/12
apiServer:
  certSANs:
  - ${join("\n  - ", concat(local.kubernetes_api_addresses, local.kubernetes_control_plane_addresses))}
  extraArgs:
    max-requests-inflight: "1000"
    max-mutating-requests-inflight: "500"
    default-watch-cache-size: "500"
    watch-cache-sizes: "persistentvolumeclaims#1000,persistentvolumes#1000"
controllerManager:
  extraArgs:
    cluster-cidr: "10.32.0.0/12"
    deployment-controller-sync-period: "50s"
EOT
  }

  provisioner "remote-exec" {
    inline = [
      "tr -d '\\r' < /tmp/config.new.yaml > /tmp/config.yaml",
      "rm -f /tmp/config.new.yaml",
      "kubeadm init --config=/tmp/config.yaml --upload-certs",
    ]
  }
}

resource "random_string" "kubernetes_bootstrap_token" {
  count = "${var.master ? 2 : 0}"

  length  = "${count.index == 0 ? 6 : 16}"
  special = false
  upper   = false
}

resource "random_id" "kubernetes_certificate_key" {
  count = "${var.master ? 1 : 0}"

  byte_length = 32
}
#===============================================================================
# STEP 4: Join cluster
#===============================================================================
resource "null_resource" "kubernetes_join" {
  count      = "${max(var.master ? length(clouddk_server.node) - 1 : length(clouddk_server.node), 0)}"
  depends_on = ["null_resource.kubernetes_init"]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.node[(var.master ? count.index + 1 : count.index)].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.private_ssh_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'KUBELET_EXTRA_ARGS=--cloud-provider=external --container-log-max-files=2 --container-log-max-size=64Mi --node-ip=${element(flatten(clouddk_server.node[(var.master ? count.index + 1 : count.index)].network_interface_addresses), 0)} --node-labels=kubernetes.cloud.dk/node-pool=${var.node_pool_name}' >> /etc/default/kubelet",
      "kubeadm join ${element(local.kubernetes_api_addresses, 0)}:${element(local.kubernetes_api_ports, 0)} --token ${local.kubernetes_bootstrap_token} --discovery-token-unsafe-skip-ca-verification ${var.master ? "--control-plane" : ""} --certificate-key ${local.kubernetes_certificate_key}",
    ]
  }
}
#===============================================================================
# STEP 5: Deploy cloud controller
#===============================================================================
resource "null_resource" "kubernetes_cloud_controller" {
  count      = "${var.master ? 1 : 0}"
  depends_on = ["null_resource.kubernetes_join"]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.node[0].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.private_ssh_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "file" {
    destination = "/tmp/clouddk.config.yaml"
    content     = <<EOT
apiVersion: v1
kind: Secret
metadata:
  name: clouddk-cloud-controller-manager-config
  namespace: kube-system
type: Opaque
data:
  CLOUDDK_API_ENDPOINT: ${base64encode("https://api.cloud.dk/v1")}
  CLOUDDK_API_KEY: ${base64encode(var.provider_token)}
  CLOUDDK_SSH_PRIVATE_KEY: ${base64encode(base64encode(tls_private_key.private_ssh_key.private_key_pem))}
  CLOUDDK_SSH_PUBLIC_KEY: ${base64encode(base64encode(tls_private_key.private_ssh_key.public_key_openssh))}
EOT
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "kubectl apply -f /tmp/clouddk.config.yaml",
      "rm -f /tmp/clouddk.config.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/danitso/clouddk-cloud-controller-manager/master/deployment.yaml",
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "echo Deleting all service definitions to force load balancers to be destroyed",
      "kubectl delete svc --all --all-namespaces",
      "while kubectl get svc --all-namespaces | grep -q -i loadbalancer; do sleep 1; done",
    ]
  }
}
#===============================================================================
# STEP 6: Deploy network controller
#===============================================================================
resource "null_resource" "kubernetes_network" {
  count      = "${var.master ? 1 : 0}"
  depends_on = ["null_resource.kubernetes_cloud_controller"]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.node[0].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.private_ssh_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "rm -f cni.yaml",
      "wget -O cni.yaml https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')'&'known-peers=${join(",", flatten(clouddk_server.node.*.network_interface_addresses))}",
      "kubectl apply -f cni.yaml",
      "rm -f cni.yaml",
    ]
  }
}
#===============================================================================
# STEP 7: Create service account
#===============================================================================
resource "null_resource" "kubernetes_service_account" {
  count      = "${var.master ? 1 : 0}"
  depends_on = ["null_resource.kubernetes_network"]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.node[0].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.private_ssh_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "while ! kubectl create -n kube-system serviceaccount admin; do sleep 1; done",
      "kubectl describe secret $(kubectl get secrets | grep admin | cut -f1 -d' ') | grep -E '^token' | cut -f2 -d':' | tr -d ' ' > /etc/kubernetes/token.txt",
      "kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts"
    ]
  }
}
#===============================================================================
# STEP 8: Create local KUBECONFIG file
#===============================================================================
resource "local_file" "kubernetes_config" {
  count      = "${var.master ? 1 : 0}"
  depends_on = ["null_resource.kubernetes_service_account"]

  filename          = "${path.root}/conf/${replace(var.cluster_name, "/[^A-Za-z0-9]+/", "_")}.conf"
  sensitive_content = local.kubernetes_config_raw
}
