variable "cluster_name" {
  description = "The name of the cluster"
  default     = "danitso-kubernetes-cluster"
}

variable "load_balancer_count" {
  description = "The number of load balancers"
  default     = 1
}

variable "load_balancer_memory" {
  description = "The minimum amount of memory (in megabytes) for each load balancer"
  default     = 1024
}

variable "load_balancer_processors" {
  description = "The minimum number of processors (cores) for each load balancer"
  default     = 1
}

variable "master_node_count" {
  description = "The number of master nodes"
  default     = 3
}

variable "master_node_memory" {
  description = "The minimum amount of memory (in megabytes) for each master node"
  default     = 4096
}

variable "master_node_processors" {
  description = "The minimum number of processors (cores) for each master node"
  default     = 2
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
  description = "The API key"
}

variable "provider_username" {
  description = "This variable is currently unused"
  default     = ""
}

variable "worker_node_count" {
  description = "The number of worker nodes in the default worker node pool"
  default     = 2
}

variable "worker_node_memory" {
  description = "The minimum amount of memory (in megabytes) for each node in the default worker node pool"
  default     = 4096
}

variable "worker_node_name" {
  description = "The name of the default worker node pool"
  default     = "default"
}

variable "worker_node_processors" {
  description = "The minimum number of processors for each node in the default worker node pool"
  default     = 2
}
