output "api_ca_certificate" {
  description = "The CA certificate for the Kubernetes API"
  value       = module.master_nodes.api_ca_certificate
}

output "api_endpoints" {
  description = "The endpoints for the Kubernetes API"
  value       = module.master_nodes.api_endpoints
}

output "config_file" {
  description = "The absolute path to the Kubernetes configuration file for use with kubectl"
  value       = module.master_nodes.config_file
}

output "config_raw" {
  description = "The raw Kubernetes configuration"
  value       = module.master_nodes.config_raw
  sensitive   = true
}

output "master_node_private_addresses" {
  description = "The private IP addresses of the master nodes"
  value       = module.master_nodes.private_addresses
}

output "master_node_public_addresses" {
  description = "The public IP addresses of the master nodes"
  value       = module.master_nodes.public_addresses
}

output "master_node_ssh_private_key" {
  description = "The private SSH key for the master nodes"
  value       = module.master_nodes.ssh_private_key
  sensitive   = true
}

output "master_node_ssh_private_key_file" {
  description = "The relative path to the private SSH key for the master nodes"
  value       = module.master_nodes.ssh_private_key_file
}

output "master_node_ssh_public_key" {
  description = "The public SSH key for the master nodes"
  value       = module.master_nodes.ssh_public_key
}

output "master_node_ssh_public_key_file" {
  description = "The relative path to the public SSH key for the master nodes"
  value       = module.master_nodes.ssh_public_key_file
}

output "service_account_token" {
  description = "The token for the Cluster Admin service account"
  value       = module.master_nodes.service_account_token
  sensitive   = true
}

output "worker_node_private_addresses" {
  description = "The private IP addresses of the worker nodes"
  value       = module.worker_nodes.private_addresses
}

output "worker_node_public_addresses" {
  description = "The public IP addresses of the worker nodes"
  value       = module.worker_nodes.public_addresses
}

output "worker_node_ssh_private_key" {
  description = "The private SSH key for the worker nodes"
  value       = module.worker_nodes.ssh_private_key
  sensitive   = true
}

output "worker_node_ssh_private_key_file" {
  description = "The relative path to the private SSH key for the worker nodes"
  value       = module.worker_nodes.ssh_private_key_file
}

output "worker_node_ssh_public_key" {
  description = "The public SSH key for the worker nodes"
  value       = module.worker_nodes.ssh_public_key
}

output "worker_node_ssh_public_key_file" {
  description = "The relative path to the public SSH key for the worker nodes"
  value       = module.worker_nodes.ssh_public_key_file
}
