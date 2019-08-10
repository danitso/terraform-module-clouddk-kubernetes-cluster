module "load_balancer_server_selector" {
  source = "github.com/danitso/terraform-module-clouddk-server-selector"

  server_memory     = var.load_balancer_memory
  server_processors = var.load_balancer_processors
}
