/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
#===============================================================================
# STEP 1: Create load balancer servers
#===============================================================================
resource "clouddk_server" "load_balancer" {
  count = var.master ? max(var.load_balancer_count, 1) : 0

  hostname      = "k8s-load-balancer-${var.cluster_name}-${count.index + 1}"
  label         = "k8s-load-balancer-${var.cluster_name}-${count.index + 1}"
  root_password = random_string.root_password.result

  location_id = var.provider_location
  package_id  = module.load_balancer_server_selector.server_type
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

  provisioner "file" {
    destination = "/etc/apt/apt.conf.d/00auto-conf"
    content     = <<EOF
Dpkg::Options {
    "--force-confdef";
    "--force-confold";
}
EOF
  }

  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "while ps aux | grep -q [a]pt; do sleep 1; done",
      "while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; done",
      "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done",
      "sed -i 's/us.archive.ubuntu.com/mirrors.dotsrc.org/' /etc/apt/sources.list",
      "apt-get -q update",
      "apt-get -q upgrade -y",
      "apt-get -q dist-upgrade -y",
      "apt-get -q install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common",
      "swapoff -a",
      "sed -i '/ swap / s/^/#/' /etc/fstab",
      "echo '${trimspace(tls_private_key.private_ssh_key.public_key_openssh)}' >> ~/.ssh/authorized_keys",
      "sed -i 's/#\\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "systemctl restart ssh",
      "add-apt-repository -y ppa:vbernat/haproxy-2.0",
      "apt-get -q update",
      "apt-get -q install -y haproxy=2.0.\\*",
    ]
  }
}
#===============================================================================
# STEP 2: Optimize load balancer server configurations
#===============================================================================
resource "null_resource" "load_balancer_tuning" {
  count      = length(clouddk_server.load_balancer)
  depends_on = ["clouddk_server.load_balancer"]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.load_balancer[count.index].network_interface_addresses), 0)
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

  provisioner "file" {
    source      = "${path.module}/etc/systemd/system/haproxy.service.d/override.conf"
    destination = "/etc/systemd/system/haproxy.service.d/override.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "echo Reloading the system properties",
      "sysctl --system",
      "echo Reloading the system daemon",
      "chmod a+r /etc/systemd/system/haproxy.service.d/override.conf",
      "systemctl daemon-reload",
      "echo Restarting the HAProxy service",
      "systemctl restart haproxy",
    ]
  }

  triggers = {
    limits_conf_hash  = md5(file("${path.module}/etc/security/limits.conf"))
    sysctl_conf_hash  = md5(file("${path.module}/etc/sysctl.d/20-maximum-performance.conf"))
    haproxy_conf_hash = md5(file("${path.module}/etc/systemd/system/haproxy.service.d/override.conf"))
  }
}
#===============================================================================
# STEP 2: Generate credentials for HAProxy statistics
#===============================================================================
resource "random_string" "load_balancer_stats_password" {
  count   = var.master ? 1 : 0
  length  = 32
  special = false
}

resource "random_string" "load_balancer_stats_username" {
  count   = var.master ? 1 : 0
  length  = 16
  special = false
}
#===============================================================================
# STEP 3: Configure load balancer
#===============================================================================
resource "null_resource" "load_balancer_configuration" {
  count      = length(clouddk_server.load_balancer)
  depends_on = ["null_resource.load_balancer_tuning"]

  connection {
    type  = "ssh"
    agent = false

    host        = element(flatten(clouddk_server.load_balancer[count.index].network_interface_addresses), 0)
    port        = 22
    user        = "root"
    private_key = tls_private_key.private_ssh_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/haproxy-cfg.sh"
    destination = "/tmp/haproxy-cfg.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "echo Updating the HAProxy configuration file",
      "bash /tmp/haproxy-cfg.sh '${join(" ", local.load_balancer_listener_addresses)}' '${join(" ", local.load_balancer_listener_ports)}' '${join(" ", local.load_balancer_listener_timeouts)}' '${join(" ", local.load_balancer_target_addresses)}' '${join(" ", local.load_balancer_target_ports)}' '${join(" ", local.load_balancer_target_timeouts)}' '${element(concat(random_string.load_balancer_stats_username.*.result, list("")), 0)}' '${element(concat(random_string.load_balancer_stats_password.*.result, list("")), 0)}' > /etc/haproxy/haproxy.cfg",
      "echo Restarting the HAProxy service",
      "systemctl restart haproxy.service",
    ]
  }

  triggers = {
    config_script_hash = md5(file("${path.module}/scripts/haproxy-cfg.sh"))
    listener_addresses = join("", local.load_balancer_listener_addresses)
    listener_ports     = join("", local.load_balancer_listener_ports)
    listener_timeouts  = join("", local.load_balancer_listener_timeouts)
    package_id         = module.load_balancer_server_selector.server_type
    stats_password     = md5(element(concat(random_string.load_balancer_stats_password.*.result, list("")), 0))
    stats_username     = element(concat(random_string.load_balancer_stats_username.*.result, list("")), 0)
    target_addresses   = join("", local.load_balancer_target_addresses)
    target_ports       = join("", local.load_balancer_target_ports)
    targer_timeouts    = join("", local.load_balancer_target_timeouts)
  }
}
