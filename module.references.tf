#===============================================================================
# STEP 1: Create master nodes
#===============================================================================
module "master_nodes" {
  source = "./modules/nodes"

  cluster_name             = var.cluster_name
  load_balancer_count      = var.load_balancer_count
  load_balancer_memory     = var.load_balancer_memory
  load_balancer_processors = var.load_balancer_processors
  master                   = true
  node_count               = var.master_node_count
  node_memory              = var.master_node_memory
  node_pool_name           = "master"
  node_processors          = var.master_node_processors
  provider_location        = var.provider_location
  provider_token           = var.provider_token
}
#===============================================================================
# STEP 2: Create worker nodes (pool: default)
#===============================================================================
module "worker_nodes" {
  source = "./modules/nodes"

  bootstrap_token       = module.master_nodes.bootstrap_token
  certificate_key       = module.master_nodes.certificate_key
  cluster_name          = var.cluster_name
  control_plane_address = "${element(concat(module.master_nodes.api_addresses, list("")), 0)}${replace(module.master_nodes.initialized, "/.*/", "")}"
  control_plane_port    = element(concat(module.master_nodes.api_ports, list("")), 0)
  master                = false
  node_count            = var.worker_node_count
  node_memory           = var.worker_node_memory
  node_pool_name        = var.worker_node_pool_name
  node_processors       = var.worker_node_processors
  provider_location     = var.provider_location
  provider_token        = var.provider_token
}
