/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
#===============================================================================
# STEP 1: Create master nodes
#===============================================================================
module "master_nodes" {
  source = "./modules/nodes"

  cluster_name               = var.cluster_name
  load_balancer_count        = var.load_balancer_count
  load_balancer_memory       = var.load_balancer_memory
  load_balancer_processors   = var.load_balancer_processors
  master                     = true
  network_storage_memory     = var.network_storage_memory
  network_storage_processors = var.network_storage_processors
  node_count                 = var.master_node_count
  node_memory                = var.master_node_memory
  node_pool_name             = "master"
  node_processors            = var.master_node_processors
  provider_location          = var.provider_location
  provider_token             = var.provider_token
  unattended_upgrades        = var.master_node_unattended_upgrades
}
#===============================================================================
# STEP 2: Create worker nodes (pool: default)
#===============================================================================
module "worker_nodes" {
  source = "./modules/nodes"

  api_addresses           = compact(concat(module.master_nodes.api_addresses, list(replace(module.master_nodes.initialized, "/.*/", ""))))
  api_ports               = compact(concat(module.master_nodes.api_ports, list(replace(module.master_nodes.initialized, "/.*/", ""))))
  bootstrap_token         = module.master_nodes.bootstrap_token
  certificate_key         = module.master_nodes.certificate_key
  cluster_name            = var.cluster_name
  control_plane_addresses = compact(concat(module.master_nodes.control_plane_addresses, list(replace(module.master_nodes.initialized, "/.*/", ""))))
  control_plane_ports     = compact(concat(module.master_nodes.control_plane_ports, list(replace(module.master_nodes.initialized, "/.*/", ""))))
  master                  = false
  node_count              = var.worker_node_count
  node_memory             = var.worker_node_memory
  node_pool_name          = var.worker_node_pool_name
  node_processors         = var.worker_node_processors
  provider_location       = var.provider_location
  provider_token          = var.provider_token
  unattended_upgrades     = var.worker_node_unattended_upgrades
}
