locals {
  node_type = "${var.master ? "master" : "worker"}"
}
