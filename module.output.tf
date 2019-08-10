output "api_ca_certificate" {
  description = "The CA certificate for the Kubernetes API"
  value       = base64encode(tls_self_signed_cert.ca.cert_pem)
}

output "api_private_endpoints" {
  description = "The private endpoints for the Kubernetes API"
  value       = formatlist("https://%s:6443", compact(concat(list(module.load_balancers.load_balancer_private_dns), module.load_balancers.load_balancer_private_addresses)))
}

output "api_public_endpoints" {
  description = "The public endpoints for the Kubernetes API"
  value       = formatlist("https://%s:6443", compact(concat(list(module.load_balancers.load_balancer_public_dns), module.load_balancers.load_balancer_public_addresses)))
}

output "config_file" {
  description = "The absolute path to the Kubernetes configuration file for use with kubectl"
  value       = ""
}

output "config_raw" {
  description = "The raw Kubernetes configuration"
  value       = ""
}

output "load_balancer_private_addresses" {
  description = "The private IP addresses of the load balancers"
  value       = module.load_balancers.load_balancer_private_addresses
}

output "load_balancer_private_dns" {
  description = "The private DNS record for the load balancers"
  value       = module.load_balancers.load_balancer_private_dns
}

output "load_balancer_public_addresses" {
  description = "The public IP addresses of the load balancers"
  value       = module.load_balancers.load_balancer_public_addresses
}

output "load_balancer_public_dns" {
  description = "The public DNS record for the load balancers"
  value       = module.load_balancers.load_balancer_public_dns
}

output "load_balancer_ssh_private_key" {
  description = "The private SSH key for the load balancers"
  value       = module.load_balancers.load_balancer_ssh_private_key
  sensitive   = true
}

output "load_balancer_ssh_private_key_file" {
  description = "The relative path to the private SSH key for the load balancers"
  value       = module.load_balancers.load_balancer_ssh_private_key_file
}

output "load_balancer_ssh_public_key" {
  description = "The public SSH key for the load balancers"
  value       = module.load_balancers.load_balancer_ssh_public_key
}

output "load_balancer_ssh_public_key_file" {
  description = "The relative path to the public SSH key for the load balancers"
  value       = module.load_balancers.load_balancer_ssh_public_key_file
}

output "load_balancer_stats_password" {
  description = "The password for the load balancer statistics"
  value       = module.load_balancers.load_balancer_stats_password
  sensitive   = true
}

output "load_balancer_stats_urls" {
  description = "The URLs for the load balancer statistics"
  value       = module.load_balancers.load_balancer_stats_urls
}

output "load_balancer_stats_username" {
  description = "The username for the load balancer statistics"
  value       = module.load_balancers.load_balancer_stats_username
}

output "master_node_private_addresses" {
  description = "The private IP addresses of the master nodes"
  value       = []
}

output "master_node_public_addresses" {
  description = "The public IP addresses of the master nodes"
  value       = flatten(clouddk_server.master_node.*.network_interface_addresses)
}

output "master_node_ssh_private_key" {
  description = "The private SSH key for the master nodes"
  value       = tls_private_key.master_node_ssh.private_key_pem
  sensitive   = true
}

output "master_node_ssh_private_key_file" {
  description = "The relative path to the private SSH key for the master nodes"
  value       = local_file.master_node_private_ssh_key.filename
}

output "master_node_ssh_public_key" {
  description = "The public SSH key for the master nodes"
  value       = tls_private_key.master_node_ssh.public_key_openssh
}

output "master_node_ssh_public_key_file" {
  description = "The relative path to the public SSH key for the master nodes"
  value       = local_file.master_node_public_ssh_key.filename
}

output "service_account_token" {
  description = "The token for the Cluster Admin service account"
  value       = trimspace(data.kubernetes_token.contents)
  sensitive   = true
}

output "worker_node_certificate_key" {
  description = "The certificate key for use when joining the Kubernetes cluster"
  value       = random_id.kubernetes_certificate_key.hex
  sensitive   = true
}

output "worker_node_private_addresses" {
  description = "The private IP addresses of the worker nodes"
  value       = module.worker_nodes.worker_node_private_addresses
}

output "worker_node_public_addresses" {
  description = "The public IP addresses of the worker nodes"
  value       = module.worker_nodes.worker_node_public_addresses
}

output "worker_node_ssh_private_key" {
  description = "The private SSH key for the worker nodes"
  value       = module.worker_nodes.worker_node_ssh_private_key
  sensitive   = true
}

output "worker_node_ssh_private_key_file" {
  description = "The relative path to the private SSH key for the worker nodes"
  value       = module.worker_nodes.worker_node_ssh_private_key_file
}

output "worker_node_ssh_public_key" {
  description = "The public SSH key for the worker nodes"
  value       = module.worker_nodes.worker_node_ssh_public_key
}

output "worker_node_ssh_public_key_file" {
  description = "The relative path to the public SSH key for the worker nodes"
  value       = module.worker_nodes.worker_node_ssh_public_key_file
}

output "worker_node_token" {
  description = "The token for use when joining the Kubernetes cluster"
  value       = join(".", random_string.kubernetes_bootstrap_token.*.result)
  sensitive   = true
}

output "worker_node_token_ca_certicate_hash" {
  description = "The SHA256 checksum of the CA certificate for use when joining the Kubernetes cluster"
  value       = ""
}
