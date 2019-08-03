resource "null_resource" "etcd" {
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
      "mkdir -p /etc/etcd /var/lib/etcd",
    ]
  }

  provisioner "file" {
    content     = tls_self_signed_cert.ca.cert_pem
    destination = "/etc/etcd/ca.pem"
  }

  provisioner "file" {
    content     = tls_private_key.etcd.private_key_pem
    destination = "/etc/etcd/kubernetes-key.pem"
  }

  provisioner "file" {
    content     = tls_locally_signed_cert.etcd.cert_pem
    destination = "/etc/etcd/kubernetes.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "wget https://github.com/etcd-io/etcd/releases/download/v${local.etcd_version}/etcd-v${local.etcd_version}-linux-amd64.tar.gz",
      "tar xzvf etcd-v${local.etcd_version}-linux-amd64.tar.gz",
      "mv etcd-v${local.etcd_version}-linux-amd64/etcd* /usr/local/bin/",
      "chmod a+x /usr/local/bin/etcd*",
      "rm -rf etcd-v${local.etcd_version}-linux-amd64*",
      "mkdir -p /etc/systemd/system",
    ]
  }

  provisioner "file" {
    content     = <<EOT
[Unit]
Description=etcd
Documentation=https://github.com/etcd-io/etcd

[Service]
ExecStart=/usr/local/bin/etcd \
  --name ${element(flatten(clouddk_server.master_node[count.index].network_interface_addresses), 0)} \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --initial-advertise-peer-urls https://${element(flatten(clouddk_server.master_node[count.index].network_interface_addresses), 0)}:2380 \
  --listen-peer-urls https://${element(flatten(clouddk_server.master_node[count.index].network_interface_addresses), 0)}:2380 \
  --listen-client-urls https://${element(flatten(clouddk_server.master_node[count.index].network_interface_addresses), 0)}:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://${element(flatten(clouddk_server.master_node[count.index].network_interface_addresses), 0)}:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster ${join(",", formatlist("%s=https://%s:2380", flatten(clouddk_server.master_node.*.network_interface_addresses), flatten(clouddk_server.master_node.*.network_interface_addresses)))} \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
Type=notify

[Install]
WantedBy=multi-user.target
EOT
    destination = "/tmp/etcd.service"
  }

  provisioner "remote-exec" {
    inline = [
      "tr -d '\\r' < /tmp/etcd.service > /etc/systemd/system/etcd.service",
      "rm -f /tmp/etcd.service",
      "systemctl daemon-reload",
      "systemctl enable etcd",
      "systemctl start etcd",
      "systemctl restart etcd",
    ]
  }

  triggers = {
    addresses = "${md5(join(",", flatten(clouddk_server.master_node[count.index].network_interface_addresses)))}"
    ca_cert   = "${md5(tls_self_signed_cert.ca.cert_pem)}",
    etcd_cert = "${md5(tls_locally_signed_cert.etcd.cert_pem)}",
    etcd_key  = "${md5(tls_private_key.etcd.private_key_pem)}",
  }
}

resource "tls_private_key" "etcd" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "etcd" {
    key_algorithm   = "RSA"
    private_key_pem = tls_private_key.etcd.private_key_pem

    dns_names    = ["localhost"]
    ip_addresses = concat(flatten(clouddk_server.master_node.*.network_interface_addresses), list("127.0.0.1"))

    subject {
        common_name         = "Kubernetes"
        country             = "DK"
        organization        = "Kubernetes"
        organizational_unit = "Kubernetes"
        locality            = "Copenhagen"
    }
}

resource "tls_locally_signed_cert" "etcd" {
    cert_request_pem   = tls_cert_request.etcd.cert_request_pem

    ca_key_algorithm   = "RSA"
    ca_private_key_pem = tls_private_key.ca.private_key_pem
    ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

    validity_period_hours = 175319

    allowed_uses = [
        "digital_signature",
        "key_agreement",
        "key_encipherment",
        "server_auth",
        "client_auth",
    ]
}
