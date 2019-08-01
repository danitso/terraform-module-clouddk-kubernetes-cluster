variable "cluster_name" {
  description = "The name of the cluster"
  default     = "new-k8s-cluster"
}

variable "load_balancer_count" {
  description = "The amount of load balancers"
  default     = 1
}

variable "master_node_count" {
  description = "The amount of master nodes"
  default     = 3
}

variable "master_node_memory" {
  description = "The amount of memory (in megabytes) for each master node"
  default     = 8192
}

variable "provider_location" {
  description = "The cluster's geographical location"
  default     = "dk1"
}

variable "provider_password" {
  description = "This variable is currently unused"
  default     = ""
}

variable "provider_token" {
  description = "The Cloud.dk API key"
}

variable "provider_username" {
  description = "This variable is currently unused"
  default     = ""
}

variable "worker_node_count" {
  description = "The amount of worker nodes"
  default     = 2
}

variable "worker_node_limit" {
  description = "This variable is currently unused"
  default     = 0
}

variable "worker_node_memory" {
  description = "The amount of memory (in megabytes) for each worker node"
  default     = 4096
}
