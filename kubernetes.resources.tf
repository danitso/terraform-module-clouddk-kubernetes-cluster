resource "null_resource" "kubernetes" {
  count = max(var.master_node_count, 1)

  depends_on = [
    "null_resource.docker",
    "null_resource.etcd",
  ]

  connection {
    type  = "ssh"
    agent = false

    host     = "${element(flatten(clouddk_server.master_node[count.index].network_interface_addresses), 0)}"
    port     = 22
    user     = "root"
    password = "${random_string.master_node_root_password.result}"
    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -",
      "echo 'deb http://apt.kubernetes.io kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list",
      "DEBIAN_FRONTEND=noninteractive apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y kubelet kubeadm kubectl",
    ]
  }
}
