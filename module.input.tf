/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

variable "cluster_name" {
  description = "The name of the cluster"
  default     = "clouddk-kubernetes-cluster"
  type        = string
}

variable "load_balancer_count" {
  description = "The number of load balancers"
  default     = 1
  type        = number
}

variable "load_balancer_memory" {
  description = "The minimum amount of memory (in megabytes) for each load balancer"
  default     = 1024
  type        = number
}

variable "load_balancer_processors" {
  description = "The minimum number of processors (cores) for each load balancer"
  default     = 1
  type        = number
}

variable "master_node_count" {
  description = "The number of master nodes"
  default     = 3
  type        = number
}

variable "master_node_memory" {
  description = "The minimum amount of memory (in megabytes) for each master node"
  default     = 4096
  type        = number
}

variable "master_node_processors" {
  description = "The minimum number of processors (cores) for each master node"
  default     = 2
  type        = number
}

variable "provider_location" {
  description = "The cluster's geographical location"
  default     = "dk1"
  type        = string
}

variable "provider_password" {
  description = "This variable is currently unused"
  default     = ""
  type        = string
}

variable "provider_token" {
  description = "The API key"
  type        = string
}

variable "provider_username" {
  description = "This variable is currently unused"
  default     = ""
  type        = string
}

variable "worker_node_count" {
  description = "The number of worker nodes in the default worker node pool"
  default     = 2
  type        = number
}

variable "worker_node_memory" {
  description = "The minimum amount of memory (in megabytes) for each node in the default worker node pool"
  default     = 4096
  type        = number
}

variable "worker_node_pool_name" {
  description = "The name of the worker node pool"
  default     = "default"
  type        = string
}

variable "worker_node_processors" {
  description = "The minimum number of processors for each node in the default worker node pool"
  default     = 2
  type        = number
}
