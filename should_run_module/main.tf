
terraform {
  required_version = ">= 0.14"
  backend "s3" {
    bucket = "server-backups-nir"
    key    = "tf/should"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

variable "path" {
  type        = string
  description = "path"
  default     = "./modules"
}

variable "hash" {
  type        = string
  description = "hash trigger"
  default     = ""
}

module "example_module" {
  source = "./modules"
}

output "random" {
  value = module.example_module.random
}

output "path" {
  value = var.path
}

output "fileset" {
  value = fileset(var.path, "**")
}

output "hash" {
  value = sha1(join("", [for f in fileset(var.path, "**") : filesha1(f)]))
}
