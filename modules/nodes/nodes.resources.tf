#===============================================================================
# STEP 1: Create node servers
#===============================================================================
resource "clouddk_server" "node" {
  count = max(var.node_count, (var.master ? 1 : 0))

  hostname      = "k8s-${local.node_type}-node-${var.cluster_name}-${count.index + 1}"
  label         = "k8s-${local.node_type}-node-${var.cluster_name}-${count.index + 1}"
  root_password = "${random_string.root_password.result}"

  location_id = var.provider_location
  package_id  = module.node_server_selector.server_type
  template_id = "ubuntu-18.04-x64"

  connection {
    type  = "ssh"
    agent = false

    host     = element(flatten(self.network_interface_addresses), 0)
    port     = 22
    user     = "root"
    password = random_string.root_password.result
    timeout  = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; done",
      "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done",
      "apt-get -q update",
      "apt-get -q install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
      "swapoff -a",
      "sed -i '/ swap / s/^/#/' /etc/fstab",
      "echo '${trimspace(tls_private_key.private_ssh_key.public_key_openssh)}' >> ~/.ssh/authorized_keys",
      "sed -i 's/#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "systemctl restart ssh",
    ]
  }
}
#===============================================================================
# STEP 2: Optimize node server configurations
#===============================================================================
resource "null_resource" "node_tuning" {
  count      = length(clouddk_server.node)
  depends_on = ["clouddk_server.node"]

  connection {
    type  = "ssh"
    agent = false

    host        = "${element(flatten(clouddk_server.node[count.index].network_interface_addresses), 0)}"
    port        = 22
    user        = "root"
    private_key = tls_private_key.private_ssh_key.private_key_pem
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

  provisioner "file" {
    source      = "${path.module}/etc/systemd/network/10-weave.network"
    destination = "/etc/systemd/network/10-weave.network"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl restart systemd-networkd",
    ]
  }

  triggers = {
    limits_conf_hash = "${md5(file("${path.module}/etc/security/limits.conf"))}"
    sysctl_conf_hash = "${md5(file("${path.module}/etc/sysctl.d/20-maximum-performance.conf"))}"
  }
}
