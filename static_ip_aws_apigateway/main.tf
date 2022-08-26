
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

resource "aws_security_group" "security_group_endpoint" {
  name        = "Static ip gateway Security Group"
  description = "allow https traffic VPC"
  vpc_id      = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "static-apigateway-security-group-endpoint" }, local.tags)
}

resource "aws_vpc_endpoint" "apigateway" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.security_group_endpoint.id,
  ]
  subnet_ids = [local.subnet_private_ids]
  tags       = merge({ Name = "static-apigateway-endpoint" }, local.tags)
}

resource "aws_eip" "nlb_eip" {
  tags = merge({ Name = "nlb_eip" }, local.tags)
}

resource "aws_lb" "network_load_balancer" {
  name               = "network-load-balancer-static-ip"
  load_balancer_type = "network"
  internal           = false

  subnet_mapping {
    subnet_id     = local.subnet_public_ids
    allocation_id = aws_eip.nlb_eip.id
  }

  enable_cross_zone_load_balancing = false
  tags                             = merge({ Name = "static-apigateway-endpoint" }, local.tags)
}

resource "aws_lb_target_group" "endpoint_target" {

  port        = 443
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  depends_on = [
    aws_lb.network_load_balancer
  ]

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_network_interface" "apigw_endpoint_eni" {
  for_each = aws_vpc_endpoint.apigateway.network_interface_ids
  id       = each.value
}

resource "aws_lb_target_group_attachment" "apigw_endpoint_eip" {
  for_each         = data.aws_network_interface.apigw_endpoint_eni
  target_group_arn = aws_lb_target_group.endpoint_target.arn
  target_id        = each.value.private_ip
  port             = 443
}
