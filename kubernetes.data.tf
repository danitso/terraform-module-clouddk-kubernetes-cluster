data "sftp_remote_file" "kubernetes_token" {
  allow_missing = true

  host        = element(flatten(clouddk_server.master_node[0].network_interface_addresses), 0)
  user        = "root"
  private_key = tls_private_key.master_node_ssh.private_key_pem

  path = "/etc/kubernetes/token.txt"

  triggers = {
    init_id = null_resource.kubernetes_master_init.id
  }
}
