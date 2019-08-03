resource "null_resource" "docker" {
  count = max(var.master_node_count, 1)

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
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "apt-key fingerprint 0EBFCD88",
      "add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable'",
      "DEBIAN_FRONTEND=noninteractive apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io",
    ]
  }
}
