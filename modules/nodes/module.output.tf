/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

output "api_addresses" {
  description = "The API addresses"
  value       = local.kubernetes_api_addresses
}

output "api_ca_certificate" {
  description = "The CA certificate for the Kubernetes API"
  value       = base64encode(element(concat(tls_self_signed_cert.ca_certificate.*.cert_pem, list("")), 0))
}

output "api_endpoints" {
  description = "The API endpoints"
  value       = local.kubernetes_api_endpoints
}

output "api_load_balancing_stats_password" {
  description = "The password for the API load balancing statistics page"
  value       = element(concat(random_string.load_balancer_stats_password.*.result, list("")), 0)
  sensitive   = true
}

output "api_load_balancing_stats_urls" {
  description = "The API load balancing statistics URLs"
  value       = formatlist("http://%s:61200/load-balancer-stats", local.kubernetes_api_addresses)
}

output "api_load_balancing_stats_username" {
  description = "The username for the API load balancing statistics page"
  value       = element(concat(random_string.load_balancer_stats_username.*.result, list("")), 0)
}

output "api_ports" {
  description = "The API ports"
  value       = local.kubernetes_api_ports
}

output "bootstrap_token" {
  description = "The bootstrap token"
  value       = local.kubernetes_bootstrap_token
  sensitive   = true
}

output "certificate_key" {
  description = "The key for the certificate secret"
  value       = local.kubernetes_certificate_key
  sensitive   = true
}

output "config_file" {
  description = "The relative path to the configuration file for use with kubectl"
  value       = element(concat(local_file.kubernetes_config.*.filename, list("")), 0)
}

output "config_raw" {
  description = "The raw configuration for use with kubectl"
  value       = local.kubernetes_config_raw
  sensitive   = true
}

output "control_plane_addresses" {
  description = "The control plane addresses"
  value       = local.kubernetes_control_plane_addresses
}

output "control_plane_ports" {
  description = "The control plane ports"
  value       = local.kubernetes_control_plane_ports
}

output "initialized" {
  value = "1${replace(join(",", concat(
    null_resource.kubernetes_init.*.id,
    null_resource.kubernetes_join.*.id,
    null_resource.kubernetes_cloud_controller.*.id,
    null_resource.kubernetes_network.*.id,
    null_resource.kubernetes_csi_driver.*.id,
    null_resource.kubernetes_service_account.*.id
  )), "/.*/", "")}"
}

output "private_addresses" {
  description = "The private IP addresses of the nodes"
  value       = []
}

output "public_addresses" {
  description = "The public IP addresses of the nodes"
  value       = flatten(clouddk_server.node.*.network_interface_addresses)
}

output "service_account_token" {
  description = "The token for the Cluster Admin service account"
  value       = local.kubernetes_service_account_token
  sensitive   = true
}

output "ssh_private_key" {
  description = "The private SSH key for the nodes"
  value       = tls_private_key.private_ssh_key.private_key_pem
  sensitive   = true
}

output "ssh_private_key_file" {
  description = "The relative path to the private SSH key for the nodes"
  value       = local_file.private_ssh_key.filename
}

output "ssh_public_key" {
  description = "The public SSH key for the nodes"
  value       = tls_private_key.private_ssh_key.public_key_openssh
}

output "ssh_public_key_file" {
  description = "The relative path to the public SSH key for the master nodes"
  value       = local_file.public_ssh_key.filename
}
