resource "local_file" "load_balancer_private_ssh_key" {
  filename          = "${path.module}/keys/id_rsa_load_balancer"
  sensitive_content = module.load_balancers.load_balancer_ssh_private_key
}

resource "local_file" "load_balancer_public_ssh_key" {
  filename = "${path.module}/keys/id_rsa_load_balancer.pub"
  content  = module.load_balancers.load_balancer_ssh_public_key
}
