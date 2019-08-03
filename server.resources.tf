resource "clouddk_server" "master_node" {
  count = max(var.master_node_count, 1)

  hostname      = "k8s-master-${var.cluster_name}-${count.index + 1}"
  label         = "k8s-master-${var.cluster_name}-${count.index + 1}"
  root_password = "${random_string.master_node_root_password.result}"

  location_id = var.provider_location
  package_id  = module.server_selector.server_type
  template_id = "ubuntu-18.04-x64"

  connection {
    type  = "ssh"
    agent = false

    host     = "${element(flatten(self.network_interface_addresses), 0)}"
    port     = 22
    user     = "root"
    password = "${random_string.master_node_root_password.result}"

    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
      "swapoff -a",
      "sed -i '/ swap / s/^/#/' /etc/fstab",
    ]
  }
}

resource "random_string" "master_node_root_password" {
  length = 64
}
