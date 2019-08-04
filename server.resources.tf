resource "clouddk_server" "master_node" {
  count = max(var.master_node_count, 1)

  hostname      = "k8s-master-node-${var.cluster_name}-${count.index + 1}"
  label         = "k8s-master-node-${var.cluster_name}-${count.index + 1}"
  root_password = "${random_string.master_node_root_password.result}"

  location_id = var.provider_location
  package_id  = module.server_selector.server_type
  template_id = "ubuntu-18.04-x64"

  connection {
    type  = "ssh"
    agent = false

    host     = element(flatten(self.network_interface_addresses), 0)
    port     = 22
    user     = "root"
    password = random_string.master_node_root_password.result
    timeout  = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
      "swapoff -a",
      "sed -i '/ swap / s/^/#/' /etc/fstab",
      "echo '${tls_private_key.master_node_ssh.public_key_openssh}' >> ~/.ssh/authorized_keys",
      "sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "systemctl restart ssh",
    ]
  }
}

resource "null_resource" "master_node_tuning" {
  count = max(var.master_node_count, 1)

  depends_on = ["clouddk_server.master_node"]

  connection {
    type  = "ssh"
    agent = false

    host        = "${element(flatten(clouddk_server.master_node[count.index].network_interface_addresses), 0)}"
    port        = 22
    user        = "root"
    private_key = tls_private_key.master_node_ssh.private_key_pem
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo Creating missing directories",
      "mkdir -p /etc/security/ /etc/sysctl.d /etc/systemd/system/haproxy.service.d",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/etc/security/limits.conf"
    destination = "/etc/security/limits.conf"
  }

  provisioner "file" {
    source      = "${path.module}/etc/sysctl.d/20-maximum-performance.conf"
    destination = "/etc/sysctl.d/20-maximum-performance.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "echo Reloading the system properties",
      "sysctl --system",
    ]
  }

  triggers = {
    limits_conf_hash  = "${md5(file("${path.module}/etc/security/limits.conf"))}"
    sysctl_conf_hash  = "${md5(file("${path.module}/etc/sysctl.d/20-maximum-performance.conf"))}"
  }
}

resource "local_file" "master_node_private_ssh_key" {
  filename          = "${path.module}/keys/id_rsa_master_node"
  sensitive_content = tls_private_key.master_node_ssh.private_key_pem
}

resource "local_file" "master_node_public_ssh_key" {
  filename = "${path.module}/keys/id_rsa_master_node.pub"
  content  = tls_private_key.master_node_ssh.public_key_openssh
}

resource "random_string" "master_node_root_password" {
  length = 64
}

resource "tls_private_key" "master_node_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
