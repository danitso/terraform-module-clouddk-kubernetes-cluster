#===============================================================================
# STEP 1: Generate SSH key pair
#===============================================================================
resource "local_file" "private_ssh_key" {
  filename          = "${path.root}/keys/id_rsa_${local.node_type}_${replace(var.cluster_name, "/[^A-Za-z0-9]+/", "_")}"
  sensitive_content = tls_private_key.private_ssh_key.private_key_pem
}

resource "local_file" "public_ssh_key" {
  filename = "${path.root}/keys/id_rsa_${local.node_type}_${replace(var.cluster_name, "/[^A-Za-z0-9]+/", "_")}.pub"
  content  = tls_private_key.private_ssh_key.public_key_openssh
}

resource "tls_private_key" "private_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
