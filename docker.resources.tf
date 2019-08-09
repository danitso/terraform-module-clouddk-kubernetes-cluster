resource "null_resource" "docker" {
  count = max(var.master_node_count, 1)

  depends_on = [
    "null_resource.master_node_tuning",
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
      "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "apt-key fingerprint 0EBFCD88",
      "add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable'",
      "DEBIAN_FRONTEND=noninteractive apt-get -q update",
      "DEBIAN_FRONTEND=noninteractive apt-get -q install -y docker-ce=5:18.09.8~3-0~ubuntu-xenial docker-ce-cli=5:18.09.8~3-0~ubuntu-xenial containerd.io",
    ]
  }

  provisioner "file" {
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
    destination = "/etc/docker/daemon.json"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/systemd/system/docker.service.d",
      "systemctl daemon-reload",
      "systemctl restart docker",
    ]
  }
}
