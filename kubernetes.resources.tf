resource "null_resource" "kubernetes_master_install" {
  count = max(var.master_node_count, 1)

  depends_on = [
    "null_resource.docker",
  ]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.master_node[count.index].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.master_node_ssh.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -",
      "echo 'deb http://apt.kubernetes.io kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list",
      "DEBIAN_FRONTEND=noninteractive apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y kubelet kubeadm kubectl",
      "mkdir -p /var/lib/kubelet/pki",
      "mkdir -p /etc/kubernetes/pki",
    ]
  }

  provisioner "file" {
    content     = tls_self_signed_cert.ca.cert_pem
    destination = "/etc/kubernetes/pki/ca.crt"
  }

  provisioner "file" {
    content     = tls_private_key.ca.private_key_pem
    destination = "/etc/kubernetes/pki/ca.key"
  }
}

resource "null_resource" "kubernetes_master_init" {
  depends_on = [
    "null_resource.kubernetes_master_install",
  ]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.master_node[0].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.master_node_ssh.private_key_pem
    timeout     = "5m"
  }

  provisioner "file" {
    content     = <<EOT
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
bootstrapTokens:
- token: "${join(".", random_string.kubernetes_bootstrap_token.*.result)}"
  description: "default kubeadm bootstrap token"
  ttl: "0"
localAPIEndpoint:
  advertiseAddress: ${element(flatten(clouddk_server.master_node[0].network_interface_addresses), 0)}
  bindPort: 6443
certificateKey: "${random_id.kubernetes_certificate_key.hex}"
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: stable
clusterName: ${var.cluster_name}
controlPlaneEndpoint: ${element(module.load_balancers.load_balancer_public_addresses, 0)}:6443
certificatesDir: /etc/kubernetes/pki
networking:
  podSubnet: 10.32.0.0/12
apiServer:
  certSANs:
  - ${join("\n  - ", module.load_balancers.load_balancer_public_addresses)}
  extraArgs:
    max-requests-inflight: "1000"
    max-mutating-requests-inflight: "500"
    default-watch-cache-size: "500"
    watch-cache-sizes: "persistentvolumeclaims#1000,persistentvolumes#1000"

controllerManager:
  extraArgs:
    cloud-provider: "external"
    cluster-cidr: "10.32.0.0/12"
    deployment-controller-sync-period: "50s"
EOT
    destination = "/tmp/config.new.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "tr -d '\\r' < /tmp/config.new.yaml > /tmp/config.yaml",
      "rm -f /tmp/config.new.yaml",
      "kubeadm init --config=/tmp/config.yaml --upload-certs",
    ]
  }
}

resource "null_resource" "kubernetes_master_join" {
  count = max(var.master_node_count - 1, 0)

  depends_on = [
    "null_resource.kubernetes_master_init",
  ]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.master_node[count.index + 1].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.master_node_ssh.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'KUBELET_EXTRA_ARGS=--cloud-provider=external' >> /etc/default/kubelet",
      "kubeadm join ${element(module.load_balancers.load_balancer_public_addresses, 0)}:6443 --token ${join(".", random_string.kubernetes_bootstrap_token.*.result)} --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key ${random_id.kubernetes_certificate_key.hex}",
    ]
  }
}

resource "null_resource" "kubernetes_network" {
  depends_on = [
    "null_resource.kubernetes_master_join",
  ]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.master_node[0].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.master_node_ssh.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "kubectl apply -f https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')",
    ]
  }
}

resource "null_resource" "kubernetes_cloud_controller" {
  depends_on = [
    "null_resource.kubernetes_network",
  ]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.master_node[0].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.master_node_ssh.private_key_pem
    timeout     = "5m"
  }

  provisioner "file" {
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
  CLOUDDK_SSH_PRIVATE_KEY: ${base64encode(base64encode(module.load_balancers.load_balancer_ssh_private_key))}
  CLOUDDK_SSH_PUBLIC_KEY: ${base64encode(base64encode(module.load_balancers.load_balancer_ssh_public_key))}
EOT
    destination = "/tmp/clouddk.config.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "kubectl apply -f /tmp/clouddk.config.yaml",
      "rm -f /tmp/clouddk.config.yaml",
      "kubectl apply -f https://raw.githubusercontent.com/danitso/clouddk-cloud-controller-manager/master/deployment.yaml",
    ]
  }
}

resource "random_string" "kubernetes_bootstrap_token" {
  count = 2

  length  = "${count.index == 0 ? 6 : 16}"
  special = false
  upper   = false
}

resource "random_id" "kubernetes_certificate_key" {
  byte_length = 32
}
