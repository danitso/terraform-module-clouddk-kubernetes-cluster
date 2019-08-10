module "node_server_selector" {
  source = "github.com/danitso/terraform-module-clouddk-server-selector"

  server_memory     = var.node_memory
  server_processors = var.node_processors
}
