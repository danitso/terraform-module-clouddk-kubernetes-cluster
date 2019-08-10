locals {
  kubernetes_config_raw = <<EOF
current-context: ${var.cluster_name}
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${base64encode(tls_self_signed_cert.ca.cert_pem)}
    server: ${element(formatlist("https://%s:6443", compact(concat(list(module.load_balancers.load_balancer_public_dns), module.load_balancers.load_balancer_public_addresses))), 0)}
  name: ${var.cluster_name}
contexts:
- context:
    cluster: ${var.cluster_name}
    namespace: default
    user: ${var.cluster_name}
  name: ${var.cluster_name}
kind: Config
preferences:
  colors: true
users:
- name: ${var.cluster_name}
  user:
    token: ${local.kubernetes_service_account_token}
EOF

  kubernetes_service_account_token = trimspace(data.sftp_remote_file.kubernetes_token.contents)
}
