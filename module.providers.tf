provider "clouddk" {
  key = var.provider_token
}

provider "local" {
  version = "~> 1.3"
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.1"
}

provider "tls" {
  version = "~> 2.0"
}
