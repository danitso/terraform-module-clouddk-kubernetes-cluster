module "server_selector" {
  source = "github.com/danitso/terraform-module-clouddk-server-selector"

  server_memory     = var.master_node_memory
  server_processors = var.master_node_processors
}
