/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
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
      "while ps aux | grep -q [a]pt; do sleep 1; done",
      "while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; done",
      "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done",
      "curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -",
      "echo 'deb http://apt.kubernetes.io kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "apt-key fingerprint 0EBFCD88",
      "add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable'",
      "apt-get -q update",
      "apt-get -q install -y ${join(" ", local.kubernetes_packages)}",
    ]
  }

  provisioner "file" {
    destination = "/etc/docker/daemon.json"
    content     = <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "insecure-registries": ["${local.kubernetes_subnet}"],
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
  count        = var.master ? 1 : 0
  input        = ["6443"]
  result_count = length(clouddk_server.load_balancer)
}

resource "random_shuffle" "control_plane_ports" {
  count        = var.master ? 1 : 0
  input        = ["6443"]
  result_count = length(clouddk_server.node)
}

resource "tls_private_key" "ca_private_key" {
  count = var.master ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca_certificate" {
  count = var.master ? 1 : 0

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
  count      = var.master ? 1 : 0
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
    node-labels: "${local.kubernetes_node_pool_label}"
certificateKey: "${local.kubernetes_certificate_key}"
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: v${local.kubernetes_version}
clusterName: ${var.cluster_name}
controlPlaneEndpoint: ${element(local.kubernetes_api_addresses, 0)}:${element(local.kubernetes_api_ports, 0)}
certificatesDir: /etc/kubernetes/pki
networking:
  podSubnet: ${local.kubernetes_subnet}
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
    cluster-cidr: "${local.kubernetes_subnet}"
    cluster-name: "${var.cluster_name}"
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


  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "[ ! -f /etc/kubernetes/admin.conf ] && exit 0",
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "echo Deleting all persistent volumes to force cloud servers to be destroyed",
      "kubectl delete pvc --all --all-namespaces",
      "while kubectl get pvc --all-namespaces | grep -q -i clouddk; do sleep 2; done",
      "kubectl delete pv --all --all-namespaces",
      "while kubectl get pv --all-namespaces | grep -q -i clouddk; do sleep 2; done",
      "echo Deleting all service definitions to force cloud servers to be destroyed",
      "kubectl delete svc --all --all-namespaces",
      "while kubectl get svc --all-namespaces | grep -q -i loadbalancer; do sleep 2; done",
    ]
  }
}

resource "random_string" "kubernetes_bootstrap_token" {
  count = var.master ? 2 : 0

  length  = count.index == 0 ? 6 : 16
  special = false
  upper   = false
}

resource "random_id" "kubernetes_certificate_key" {
  count = var.master ? 1 : 0

  byte_length = 32
}
#===============================================================================
# STEP 4: Join cluster
#===============================================================================
resource "null_resource" "kubernetes_join" {
  count      = max(var.master ? length(clouddk_server.node) - 1 : length(clouddk_server.node), 0)
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
      "echo 'KUBELET_EXTRA_ARGS=--cloud-provider=external --container-log-max-files=2 --container-log-max-size=64Mi --node-ip=${element(flatten(clouddk_server.node[(var.master ? count.index + 1 : count.index)].network_interface_addresses), 0)} --node-labels=${local.kubernetes_node_pool_label}' >> /etc/default/kubelet",
      "kubeadm join ${element(local.kubernetes_api_addresses, 0)}:${element(local.kubernetes_api_ports, 0)} --token ${local.kubernetes_bootstrap_token} --discovery-token-unsafe-skip-ca-verification ${var.master ? "--control-plane" : ""} --certificate-key ${local.kubernetes_certificate_key}",
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "[ ! -f /etc/kubernetes/bootstrap-kubelet.conf ] && exit 0",
      "kubeadm reset -f",
    ]
  }
}
#===============================================================================
# STEP 5: Deploy cloud controller
#===============================================================================
resource "null_resource" "kubernetes_cloud_controller" {
  count      = var.master ? 1 : 0
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
    destination = "/tmp/clouddk.controller.yaml"
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
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: clouddk-cloud-controller-manager
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:clouddk-cloud-controller-manager
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: clouddk-cloud-controller-manager
  namespace: kube-system
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    k8s-app: clouddk-cloud-controller-manager
  name: clouddk-cloud-controller-manager
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: clouddk-cloud-controller-manager
  template:
    metadata:
      annotations:
        config-hash: ${md5(var.provider_token)}
      labels:
        k8s-app: clouddk-cloud-controller-manager
    spec:
      serviceAccountName: clouddk-cloud-controller-manager
      containers:
      - name: clouddk-cloud-controller-manager
        image: docker.io/danitso/clouddk-cloud-controller-manager:latest
        args:
        - --allocate-node-cidrs=true
        - --cloud-provider=clouddk
        - --cluster-cidr="${local.kubernetes_subnet}"
        - --cluster-name="${var.cluster_name}"
        - --configure-cloud-routes=false
        - --leader-elect=true
        - --use-service-account-credentials
        envFrom:
        - secretRef:
            name: clouddk-cloud-controller-manager-config
      hostNetwork: true
      tolerations:
      - key: node.cloudprovider.kubernetes.io/uninitialized
        value: "true"
        effect: NoSchedule
        operator: Equal
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
        operator: Exists
      - key: node.kubernetes.io/not-ready
        effect: NoSchedule
        operator: Exists
      nodeSelector:
        node-role.kubernetes.io/master: ""
EOT
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "tr -d '\\r' < /tmp/clouddk.controller.yaml > /tmp/clouddk.controller.sanitized.yaml",
      "kubectl apply -f /tmp/clouddk.controller.sanitized.yaml",
      "rm -f /tmp/clouddk.controller.yaml /tmp/clouddk.controller.sanitized.yaml",
    ]
  }

  triggers = {
    provider_token = md5(var.provider_token)
  }
}
#===============================================================================
# STEP 6: Deploy network controller
#===============================================================================
resource "null_resource" "kubernetes_network" {
  count      = var.master ? 1 : 0
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

  provisioner "file" {
    destination = "/tmp/weave.net.yaml"
    content     = <<EOT
apiVersion: v1
kind: Secret
metadata:
  name: weave-password
  labels:
    name: weave-net
  namespace: kube-system
type: Opaque
data:
  weave-password: ${base64encode(element(concat(random_string.kubernetes_network_password.*.result, list("")), 0))}
---
apiVersion: v1
kind: List
items:
  - apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: weave-net
      labels:
        name: weave-net
      namespace: kube-system
  - apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRole
    metadata:
      name: weave-net
      labels:
        name: weave-net
    rules:
      - apiGroups:
          - ''
        resources:
          - pods
          - namespaces
          - nodes
        verbs:
          - get
          - list
          - watch
      - apiGroups:
          - networking.k8s.io
        resources:
          - networkpolicies
        verbs:
          - get
          - list
          - watch
      - apiGroups:
          - ''
        resources:
          - nodes/status
        verbs:
          - patch
          - update
  - apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: ClusterRoleBinding
    metadata:
      name: weave-net
      labels:
        name: weave-net
    roleRef:
      kind: ClusterRole
      name: weave-net
      apiGroup: rbac.authorization.k8s.io
    subjects:
      - kind: ServiceAccount
        name: weave-net
        namespace: kube-system
  - apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: Role
    metadata:
      name: weave-net
      labels:
        name: weave-net
      namespace: kube-system
    rules:
      - apiGroups:
          - ''
        resourceNames:
          - weave-net
        resources:
          - configmaps
        verbs:
          - get
          - update
      - apiGroups:
          - ''
        resources:
          - configmaps
        verbs:
          - create
  - apiVersion: rbac.authorization.k8s.io/v1beta1
    kind: RoleBinding
    metadata:
      name: weave-net
      labels:
        name: weave-net
      namespace: kube-system
    roleRef:
      kind: Role
      name: weave-net
      apiGroup: rbac.authorization.k8s.io
    subjects:
      - kind: ServiceAccount
        name: weave-net
        namespace: kube-system
  - apiVersion: extensions/v1beta1
    kind: DaemonSet
    metadata:
      name: weave-net
      labels:
        name: weave-net
      namespace: kube-system
    spec:
      minReadySeconds: 5
      template:
        metadata:
          labels:
            name: weave-net
        spec:
          containers:
            - name: weave
              command:
                - /home/weave/launch.sh
                - ${join("\n                - ", local.kubernetes_control_plane_addresses)}
              env:
                - name: HOSTNAME
                  valueFrom:
                    fieldRef:
                      apiVersion: v1
                      fieldPath: spec.nodeName
                - name: IPALLOC_RANGE
                  value: "${local.kubernetes_subnet}"
                - name: WEAVE_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: weave-password
                      key: weave-password
              image: 'docker.io/weaveworks/weave-kube:${local.kubernetes_weave_net_version}'
              readinessProbe:
                httpGet:
                  host: 127.0.0.1
                  path: /status
                  port: 6784
              resources:
                requests:
                  cpu: 10m
              securityContext:
                privileged: true
              volumeMounts:
                - name: weavedb
                  mountPath: /weavedb
                - name: cni-bin
                  mountPath: /host/opt
                - name: cni-bin2
                  mountPath: /host/home
                - name: cni-conf
                  mountPath: /host/etc
                - name: dbus
                  mountPath: /host/var/lib/dbus
                - name: lib-modules
                  mountPath: /lib/modules
                - name: xtables-lock
                  mountPath: /run/xtables.lock
            - name: weave-npc
              env:
                - name: HOSTNAME
                  valueFrom:
                    fieldRef:
                      apiVersion: v1
                      fieldPath: spec.nodeName
              image: 'docker.io/weaveworks/weave-npc:${local.kubernetes_weave_net_version}'
              resources:
                requests:
                  cpu: 10m
              securityContext:
                privileged: true
              volumeMounts:
                - name: xtables-lock
                  mountPath: /run/xtables.lock
          hostNetwork: true
          hostPID: true
          restartPolicy: Always
          securityContext:
            seLinuxOptions: {}
          serviceAccountName: weave-net
          tolerations:
            - effect: NoSchedule
              operator: Exists
          volumes:
            - name: weavedb
              hostPath:
                path: /var/lib/weave
            - name: cni-bin
              hostPath:
                path: /opt
            - name: cni-bin2
              hostPath:
                path: /home
            - name: cni-conf
              hostPath:
                path: /etc
            - name: dbus
              hostPath:
                path: /var/lib/dbus
            - name: lib-modules
              hostPath:
                path: /lib/modules
            - name: xtables-lock
              hostPath:
                path: /run/xtables.lock
                type: FileOrCreate
      updateStrategy:
        type: RollingUpdate
EOT
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "tr -d '\\r' < /tmp/weave.net.yaml > /tmp/weave.net.sanitized.yaml",
      "kubectl apply -f /tmp/weave.net.sanitized.yaml",
      "rm -f /tmp/weave.net.yaml /tmp/weave.net.sanitized.yaml",
    ]
  }
}

resource "random_string" "kubernetes_network_password" {
  count  = var.master ? 1 : 0
  length = 32
}
#===============================================================================
# STEP 7: Deploy CSI driver
#===============================================================================
resource "null_resource" "kubernetes_csi_driver" {
  count      = var.master ? 1 : 0
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

  provisioner "file" {
    destination = "/tmp/clouddk-csi-driver-config.yaml"
    content     = <<EOT
apiVersion: v1
kind: Secret
metadata:
  name: clouddk-csi-driver-config
  namespace: kube-system
type: Opaque
data:
  CLOUDDK_API_ENDPOINT: ${base64encode("https://api.cloud.dk/v1")}
  CLOUDDK_API_KEY: ${base64encode(var.provider_token)}
  CLOUDDK_SERVER_MEMORY: ${base64encode(var.network_storage_memory)}
  CLOUDDK_SERVER_PROCESSORS: ${base64encode(var.network_storage_processors)}
  CLOUDDK_SSH_PRIVATE_KEY: ${base64encode(base64encode(tls_private_key.private_ssh_key.private_key_pem))}
  CLOUDDK_SSH_PUBLIC_KEY: ${base64encode(base64encode(tls_private_key.private_ssh_key.public_key_openssh))}
EOT
  }

  provisioner "remote-exec" {
    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "tr -d '\\r' < /tmp/clouddk-csi-driver-config.yaml > /tmp/clouddk-csi-driver-config.sanitized.yaml",
      "kubectl apply -f /tmp/clouddk-csi-driver-config.sanitized.yaml",
      "rm -f /tmp/clouddk-csi-driver-config*",
      "kubectl apply -f https://raw.githubusercontent.com/danitso/clouddk-csi-driver/master/deployment.yaml",
    ]
  }

  triggers = {
    network_storage_memory     = var.network_storage_memory
    network_storage_processors = var.network_storage_processors
    provider_token             = md5(var.provider_token)
  }
}
#===============================================================================
# STEP 8: Create service account
#===============================================================================
resource "null_resource" "kubernetes_service_account" {
  count      = var.master ? 1 : 0
  depends_on = ["null_resource.kubernetes_csi_driver"]

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
      "[ -f /etc/kubernetes/token.txt ] && exit 0",
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "while ! kubectl create -n kube-system serviceaccount admin; do sleep 1; done",
      "kubectl describe secret $(kubectl get secrets | grep admin | cut -f1 -d' ') | grep -E '^token' | cut -f2 -d':' | tr -d ' ' > /etc/kubernetes/token.txt",
      "kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts"
    ]
  }
}
#===============================================================================
# STEP 9: Create local KUBECONFIG file
#===============================================================================
resource "local_file" "kubernetes_config" {
  count      = var.master ? 1 : 0
  depends_on = ["null_resource.kubernetes_service_account"]

  filename          = "${path.root}/conf/${replace(var.cluster_name, "/[^A-Za-z0-9]+/", "_")}.conf"
  sensitive_content = local.kubernetes_config_raw
}
