resource "local_file" "worker_node_private_ssh_key" {
  filename          = "${path.module}/keys/id_rsa_worker_node"
  sensitive_content = module.worker_nodes.worker_node_ssh_private_key
}

resource "local_file" "worker_node_public_ssh_key" {
  filename = "${path.module}/keys/id_rsa_worker_node.pub"
  content  = module.worker_nodes.worker_node_ssh_public_key
}
