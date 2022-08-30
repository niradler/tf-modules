
terraform {
  required_version = ">= 0.14"
  backend "s3" {
    bucket = "server-backups-nir"
    key    = "tf/static_ip_gateway"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

locals {
  ports = {
    https = 443
  }
}

