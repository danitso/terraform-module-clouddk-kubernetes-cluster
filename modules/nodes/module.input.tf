/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

variable "api_addresses" {
  description = "The API addresses"
  default     = []
  type        = list(string)
}

variable "api_ports" {
  description = "The API ports"
  default     = [6443]
  type        = list(number)
}

variable "bootstrap_token" {
  description = "The bootstrap token"
  default     = ""
  type        = string
}

variable "certificate_key" {
  description = "The certificate key for the Kubernetes secret"
  default     = ""
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  default     = "danitso-kubernetes-cluster"
  type        = string
}

variable "control_plane_addresses" {
  description = "The control plane addresses"
  default     = []
  type        = list(string)
}

variable "control_plane_ports" {
  description = "The control plane ports"
  default     = [6443]
  type        = list(number)
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

variable "master" {
  description = "Whether to provision master nodes"
  default     = true
  type        = bool
}

variable "network_storage_memory" {
  description = "The minimum amount of memory (in megabytes) for network storage servers"
  default     = 4096
  type        = number
}

variable "network_storage_processors" {
  description = "The minimum number of processors (cores) for network storage servers"
  default     = 2
  type        = number
}

variable "node_count" {
  description = "The number of nodes"
  default     = 2
  type        = number
}

variable "node_memory" {
  description = "The minimum amount of memory (in megabytes) for each node"
  default     = 4096
  type        = number
}

variable "node_pool_name" {
  description = "The node pool name"
  default     = "default"
  type        = string
}

variable "node_processors" {
  description = "The minimum number of processors (cores) for each node"
  default     = 2
  type        = number
}

variable "provider_location" {
  description = "The geographical location"
  default     = "dk1"
  type        = string
}

variable "provider_token" {
  description = "The API key"
  type        = string
}

variable "unattended_upgrades" {
  description = "Whether to enable unattended OS upgrades for the nodes"
  default     = true
  type        = bool
}
