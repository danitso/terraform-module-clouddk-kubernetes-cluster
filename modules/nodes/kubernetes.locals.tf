locals {
  kubernetes_api_addresses = concat(
    slice(flatten(clouddk_server.load_balancer.*.network_interface_addresses), 0, (var.master ? length(flatten(clouddk_server.load_balancer.*.network_interface_addresses)) : 0)),
    slice(var.api_addresses, 0, (var.master ? 0 : length(var.api_addresses)))
  )
  kubernetes_api_endpoints = formatlist("https://%s:%s", local.kubernetes_api_addresses, local.kubernetes_api_ports)
  kubernetes_api_ports = concat(
    slice(flatten(random_shuffle.api_ports.*.result), 0, (var.master ? length(flatten(random_shuffle.api_ports.*.result)) : 0)),
    slice(var.api_ports, 0, (var.master ? 0 : length(var.api_ports)))
  )
  kubernetes_bootstrap_token = join(".", slice(concat(
    random_string.kubernetes_bootstrap_token.*.result,
    split(".", var.bootstrap_token),
    list("", "")
  ), 0, 2))
  kubernetes_certificate_key = element(concat(random_id.kubernetes_certificate_key.*.hex, list(var.certificate_key)), 0)
  kubernetes_control_plane_addresses = concat(
    slice(flatten(clouddk_server.node.*.network_interface_addresses), 0, (var.master ? length(flatten(clouddk_server.node.*.network_interface_addresses)) : 0)),
    slice(var.control_plane_addresses, 0, (var.master ? 0 : length(var.control_plane_addresses)))
  )
  kubernetes_control_plane_ports = concat(
    slice(flatten(random_shuffle.control_plane_ports.*.result), 0, (var.master ? length(flatten(random_shuffle.control_plane_ports.*.result)) : 0)),
    slice(var.control_plane_ports, 0, (var.master ? 0 : length(var.control_plane_ports)))
  )
  kubernetes_service_account_token = trimspace(element(concat(data.sftp_remote_file.kubernetes_token.*.contents, list("")), 0))

  kubernetes_config_raw = <<EOF
current-context: ${var.cluster_name}
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${base64encode(element(concat(tls_self_signed_cert.ca_certificate.*.cert_pem, list("")), 0))}
    server: ${element(concat(local.kubernetes_api_endpoints, list("")), 0)}
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
}
