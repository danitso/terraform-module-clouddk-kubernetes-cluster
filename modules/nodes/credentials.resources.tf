resource "random_string" "root_password" {
  length = 64

  min_lower   = 1
  min_numeric = 1
  min_upper   = 1

  special = false
}
