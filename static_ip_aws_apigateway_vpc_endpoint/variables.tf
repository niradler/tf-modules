variable "region" {
  type        = string
  description = "The region in which to create/manage resources"
  default     = "us-east-1"
}

variable "rest_api_name" {
  type        = string
  description = "Name of the API Gateway created"
  default     = "static_ip_gateway"
}

variable "rest_api_stage_name" {
  type        = string
  description = "API Gateway stage"
  default     = "dev"
}

variable "vpc_name" {
  description = "The VPC name"
  default     = "static_ip_vpc"
}

variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr_block" {
  type        = list(any)
  description = "CIDR block for Public Subnet"
  default     = ["10.0.32.0/24", "10.0.96.0/24", "10.0.224.0/24"]
}

variable "private_subnets_cidr_block" {
  type        = list(any)
  description = "CIDR block for Private Subnet"
  default     = ["10.0.0.0/19", "10.0.64.0/19", "10.0.128.0/19"]
}

variable "availability_zones" {
  type        = list(any)
  description = "AZ in which all the resources will be deployed"
  default     = ["us-east-1a"]
}

variable "vpc_tags" {
  description = "A map of tags to add to VPC"
  type        = map(string)
  default = {
    "Project" : "static_ip"
  }
}
