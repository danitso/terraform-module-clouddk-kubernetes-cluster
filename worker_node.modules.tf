module "worker_nodes" {
  source = "github.com/danitso/terraform-module-clouddk-kubernetes-nodes"

  cluster_name = var.cluster_name

  control_plane_address = element(module.load_balancers.load_balancer_public_addresses, 0)
  control_plane_port    = 6443

  provider_token = var.provider_token

  worker_node_certificate_key = random_id.kubernetes_certificate_key.hex
  worker_node_count           = var.worker_node_count
  worker_node_memory          = var.worker_node_memory
  worker_node_name            = "${var.worker_node_name}${replace(null_resource.kubernetes_network.id, "/.*/", "")}"
  worker_node_processors      = var.worker_node_processors
  worker_node_token           = join(".", random_string.kubernetes_bootstrap_token.*.result)
}
