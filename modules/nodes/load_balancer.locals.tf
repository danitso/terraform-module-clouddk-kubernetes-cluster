locals {
  load_balancer_listener_addresses = ["0.0.0.0"]
  load_balancer_listener_ports     = [6443]
  load_balancer_listener_timeouts  = [300]
  load_balancer_target_addresses   = ["${join(",", flatten(clouddk_server.node.*.network_interface_addresses))}"]
  load_balancer_target_ports       = [6443]
  load_balancer_target_timeouts    = [300]
}
