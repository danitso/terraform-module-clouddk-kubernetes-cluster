output "api_ca_certificate" {
  description = "The CA certificate for the Kubernetes API"
  value       = ""
}

output "api_private_endpoint" {
  description = "The private endpoint for the Kubernetes API"
  value       = ""
}

output "api_public_endpoint" {
  description = "The public endpoint for the Kubernetes API"
  value       = ""
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

output "load_balancer_root_password" {
  description = "The root password for the load balancers"
  value       = module.load_balancers.load_balancer_root_password
  sensitive   = true
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

output "master_node_root_password" {
  description = "The root password for the load balancers"
  value       = random_string.master_node_root_password.result
  sensitive   = true
}

output "service_account_token" {
  description = "The token for the Cluster Admin service account"
  value       = ""
  sensitive   = true
}

output "worker_node_token" {
  description = "The worker node token for the Kubernetes API"
  value       = ""
  sensitive   = true
}

output "worker_node_token_ca_certicate_hash" {
  description = "The SHA256 checksum of the worker node token's CA certificate"
  value       = ""
}
