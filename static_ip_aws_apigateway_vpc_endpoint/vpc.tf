locals {
  vpc_name                   = var.vpc_name
  cidr_block                 = var.vpc_cidr_block
  public_subnets_cidr_block  = var.public_subnets_cidr_block
  private_subnets_cidr_block = var.private_subnets_cidr_block
  availability_zones         = var.availability_zones
  tags                       = var.vpc_tags
  subnet_private_ids         = element(aws_subnet.private_subnet.*.id, 0)
  subnet_public_ids          = element(aws_subnet.public_subnet.*.id, 0)
}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = local.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge({
    Name = local.vpc_name
  }, local.tags)
}

# Subnets
# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = merge({
    Name = "${local.vpc_name} Internet Gateway"
  }, local.tags)
}

# EIP for NAT
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]
  tags       = merge({ Name = "${local.vpc_name} Gateway" }, local.tags)
}

# NAT
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)

  tags = merge({
    Name = "${local.vpc_name} Nat Gateway"
  }, local.tags)
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(local.public_subnets_cidr_block)
  cidr_block              = element(local.public_subnets_cidr_block, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = merge({
    Name = "${local.vpc_name} Public Subnet ${element(var.availability_zones, count.index)}"
  }, local.tags)
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(local.private_subnets_cidr_block)
  cidr_block              = element(local.private_subnets_cidr_block, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = false
  tags = merge({
    Name = "${local.vpc_name} Private Subnet ${element(var.availability_zones, count.index)}"
  }, local.tags)
}


# Routing tables to route traffic for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "${local.vpc_name} Private Route Table"
  }, local.tags)
}

# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "${local.vpc_name} Public Route Table"
  }, local.tags)
}

# Route for Internet Gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# Route for NAT
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

# Route table associations for Public Subnets
resource "aws_route_table_association" "public" {
  count          = length(local.public_subnets_cidr_block)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# Route table associations for Private Subnets
resource "aws_route_table_association" "private" {
  count          = length(local.private_subnets_cidr_block)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

# Default Security Group of VPC
resource "aws_security_group" "security_group" {
  name        = "${local.vpc_name} Security Group"
  description = "Default SG to allow traffic from the VPC"
  vpc_id      = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }

  tags = merge({Name = "${local.vpc_name} Security Group"}, local.tags)
}
