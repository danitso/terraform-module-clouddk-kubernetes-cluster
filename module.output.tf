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
  value       = []
}

output "load_balancer_private_dns" {
  description = "The private DNS record for the load balancers"
  value       = ""
}

output "load_balancer_public_addresses" {
  description = "The public IP addresses of the load balancers"
  value       = []
}

output "load_balancer_public_dns" {
  description = "The public DNS record for the load balancers"
  value       = ""
}

output "master_node_private_addresses" {
  description = "The private IP addresses of the master nodes"
  value       = []
}

output "master_node_public_addresses" {
  description = "The public IP addresses of the master nodes"
  value       = []
}

output "service_account_token" {
  description = "The token for the Cluster Admin service account"
  value       = ""
  sensitive   = true
}
