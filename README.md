# Kubernetes Cluster
Terraform Module for creating a Kubernetes Cluster on Cloud.dk

> **WARNING:** This project is under active development and should be considered alpha.

# Requirements
- [Terraform](https://www.terraform.io/downloads.html) 0.12+

# Input Variables

## cluster_name
The name of the cluster.

_**NOTE:** The name will be truncated to 32 characters._

## load_balancer_count
The number of load balancers.

## load_balancer_memory
The minimum amount of memory (in megabytes) for each load balancer.

## load_balancer_processors
The minimum number of processors (cores) for each load balancer.

## master_node_count
The number of master nodes.

## master_node_memory
The minimum amount of memory (in megabytes) for each master node.

## master_node_processors
The minimum number of processors (cores) for each master node.

## provider_location
The cluster's geographical location.

## provider_password
_This variable is currently unused._

## provider_token
The API key.

## provider_username
_This variable is currently unused._

## worker_node_count
The number of worker nodes in the default worker node pool.

## worker_node_memory
The minimum amount of memory (in megabytes) for each node in the default worker node pool.

## worker_node_name
The name of the default worker node pool.

## worker_node_processors
The minimum number of processors for each node in the default worker node pool.

# Output Variables

## api_ca_certificate
The CA certificate for the Kubernetes API.

## api_private_endpoints
The private endpoints for the Kubernetes API.

## api_public_endpoints
The public endpoints for the Kubernetes API.

## config_file
The absolute path to the Kubernetes configuration file for use with `kubectl`.

## config_raw
The raw Kubernetes configuration.

## load_balancer_private_addresses
The private IP addresses of the load balancers.

## load_balancer_private_dns
The private DNS record for the load balancers.

## load_balancer_public_addresses
The public IP addresses of the load balancers.

## load_balancer_public_dns
The public DNS record for the load balancers.

## load_balancer_ssh_private_key
The private SSH key for the load balancers.

## load_balancer_ssh_private_key_file
The relative path to the private SSH key for the load balancers.

## load_balancer_ssh_public_key
The public SSH key for the load balancers.

## load_balancer_ssh_public_key_file
The relative path to the public SSH key for the load balancers.

## load_balancer_stats_password
The password for the load balancer statistics.

## load_balancer_stats_urls
The URLs for the load balancer statistics.

## load_balancer_stats_username
The username for the load balancer statistics.

## master_node_private_addresses
The private IP addresses of the master nodes.

## master_node_public_addresses
The public IP addresses of the master nodes.

## master_node_ssh_private_key
The private SSH key for the master nodes.

## master_node_ssh_private_key_file
The relative path to the private SSH key for the master nodes.

## master_node_ssh_public_key
The public SSH key for the master nodes.

## master_node_ssh_public_key_file
The relative path to the public SSH key for the master nodes.

## service_account_token
The token for the Cluster Admin service account.

## worker_node_certificate_key
The certificate key for use when joining the Kubernetes cluster.

## worker_node_private_addresses
The private IP addresses of the worker nodes.

## worker_node_public_addresses
The public IP addresses of the worker nodes.

## worker_node_ssh_private_key
The private SSH key for the worker nodes.

## worker_node_ssh_private_key_file
The relative path to the private SSH key for the worker nodes.

## worker_node_ssh_public_key
The public SSH key for the worker nodes.

## worker_node_ssh_public_key_file
The relative path to the public SSH key for the worker nodes.

## worker_node_token
The token for use when joining the Kubernetes cluster.

## worker_node_token_ca_certificate_hash
The SHA256 checksum of the CA certificate for use when joining the Kubernetes cluster.
