/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
#===============================================================================
# STEP 1: Create node servers
#===============================================================================
resource "clouddk_server" "node" {
  count = max(var.node_count, (var.master ? 3 : 1))

  hostname      = "k8s-${local.node_type}-node-${var.cluster_name}${var.master ? "" : "-${var.node_pool_name}"}-${count.index + 1}"
  label         = "k8s-${local.node_type}-node-${var.cluster_name}${var.master ? "" : "-${var.node_pool_name}"}-${count.index + 1}"
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
      "sed -i 's/us.archive.ubuntu.com/mirrors.dotsrc.org/' /etc/apt/sources.list",
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
#===============================================================================
# STEP 3: Create firewall rules for node servers
#===============================================================================
resource "null_resource" "node_firewall_rules" {
  count      = length(clouddk_server.node)
  depends_on = ["null_resource.node_tuning"]

  connection {
    type  = "ssh"
    agent = false

    host        = "${element(flatten(clouddk_server.node[count.index].network_interface_addresses), 0)}"
    port        = 22
    user        = "root"
    private_key = tls_private_key.private_ssh_key.private_key_pem
    timeout     = "5m"
  }

  provisioner "file" {
    destination = "/etc/network/if-up.d/default-firewall-rules"
    content     = <<EOF
#!/bin/sh
# Skip applying the firewall rules for interfaces other than eth0
if [ "$IFACE" != "eth0" ]; then
  exit 0
fi

# Apply the firewall rules for etcd.
iptables -D INPUT -i eth0 -p tcp --dport 2379:2380 -j DROP
iptables -D INPUT -i eth0 -p tcp -s ${join(",", local.kubernetes_control_plane_addresses)},${local.kubernetes_subnet},127.0.0.1 --dport 2379:2380 -j ACCEPT

iptables -A INPUT -i eth0 -p tcp -s ${join(",", local.kubernetes_control_plane_addresses)},${local.kubernetes_subnet},127.0.0.1 --dport 2379:2380 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 2379:2380 -j DROP

# Apply the firewall rules for kubernetes.
iptables -D INPUT -i eth0 -p tcp --dport 10250:10255 -j DROP
iptables -D INPUT -i eth0 -p tcp -s ${join(",", local.kubernetes_control_plane_addresses)},${local.kubernetes_subnet},127.0.0.1 --dport 10250:10255 -j ACCEPT

iptables -A INPUT -i eth0 -p tcp -s ${join(",", local.kubernetes_control_plane_addresses)},${local.kubernetes_subnet},127.0.0.1 --dport 10250:10255 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 10250:10255 -j DROP
EOF
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /etc/network/if-up.d/default-firewall-rules",
      "iptables -D INPUT -i eth0 -p tcp --dport 2379:2380 -j DROP",
      "iptables -D INPUT -i eth0 -p tcp -s ${join(",", local.kubernetes_control_plane_addresses)},${local.kubernetes_subnet},127.0.0.1 --dport 2379:2380 -j ACCEPT",

      "iptables -A INPUT -i eth0 -p tcp -s ${join(",", local.kubernetes_control_plane_addresses)},${local.kubernetes_subnet},127.0.0.1 --dport 2379:2380 -j ACCEPT",
      "iptables -A INPUT -i eth0 -p tcp --dport 2379:2380 -j DROP",

      "iptables -D INPUT -i eth0 -p tcp --dport 10250:10255 -j DROP",
      "iptables -D INPUT -i eth0 -p tcp -s ${join(",", local.kubernetes_control_plane_addresses)},${local.kubernetes_subnet},127.0.0.1 --dport 10250:10255 -j ACCEPT",

      "iptables -A INPUT -i eth0 -p tcp -s ${join(",", local.kubernetes_control_plane_addresses)},1${local.kubernetes_subnet},127.0.0.1 --dport 10250:10255 -j ACCEPT",
      "iptables -A INPUT -i eth0 -p tcp --dport 10250:10255 -j DROP",
    ]
  }

  triggers = {
    control_plane_addresses = join(",", local.kubernetes_control_plane_addresses)
  }
}
#===============================================================================
# STEP 4: Configure unattended upgrades
#===============================================================================
resource "null_resource" "node_unattended_upgrades" {
  count      = length(clouddk_server.node)
  depends_on = ["null_resource.node_tuning"]

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
      "while fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; done",
      "while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done",
      "apt-get -q install -y unattended-upgrades",
    ]
  }

  provisioner "file" {
    destination = "/etc/apt/apt.conf.d/20auto-upgrades"
    content     = <<EOF
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Enable "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Update-Package-Lists "1";
EOF
  }

  provisioner "file" {
    destination = "/etc/apt/apt.conf.d/50unattended-upgrades"
    content     = <<EOF
Unattended-Upgrade::Allowed-Origins {
    "$${distro_id}:$${distro_codename}";
    "$${distro_id}:$${distro_codename}-security";
    "$${distro_id}ESM:$${distro_codename}";
    "$${distro_id}:$${distro_codename}-updates";
};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "00:${format("%02d", count.index * 15 % 60)}";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::OnlyOnACPower "false";
Unattended-Upgrade::Package-Blacklist {
    "containerd.io";
    "docker-ce";
    "docker-ce-cli";
    "kubeadm";
    "kubectl";
    "kubelet";
};
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Skip-Updates-On-Metered-Connections "false";
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";
EOF
  }
}
