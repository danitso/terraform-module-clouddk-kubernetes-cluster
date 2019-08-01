output "api_ca_certificate" {
  description = "The CA certificate for the Kubernetes API"
  value       = ""
}

output "api_endpoints" {
  description = "The endpoints for the Kubernetes API"
  value       = []
}

output "config_file" {
  description = "The absolute path to the Kubernetes configuration file for use with kubectl"
  value       = ""
}

output "config_raw" {
  description = "The raw Kubernetes configuration"
  value       = ""
}

output "load_balancer_addresses" {
  description = "The IP addresses of the load balancers"
  value       = []
}

output "master_node_addresses" {
  description = "The IP addresses of the master nodes"
  value       = []
}

output "service_account_token" {
  description = "The token for the Cluster Admin service account"
  value       = ""
}
