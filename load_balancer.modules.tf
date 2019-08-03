module "load_balancers" {
  source = "github.com/danitso/terraform-module-clouddk-load-balancer"

  load_balancer_count              = var.load_balancer_count
  load_balancer_memory             = var.load_balancer_memory
  load_balancer_name               = var.cluster_name
  load_balancer_processors         = var.load_balancer_processors
  load_balancer_listener_addresses = ["0.0.0.0"]
  load_balancer_listener_ports     = [6443]
  load_balancer_listener_timeouts  = [300]
  load_balancer_target_addresses   = ["${join(",", flatten(clouddk_server.master_node.*.network_interface_addresses))}"]
  load_balancer_target_ports       = [6443]
  load_balancer_target_timeouts    = [300]

  provider_token = var.provider_token
}
