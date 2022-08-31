
terraform {
  required_version = ">= 1.2.7"
  backend "s3" {
    bucket = "server-backups-nir"
    key    = "tf/ec2-tunnel"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}
data "aws_vpc" "default" {
  default = true
}

resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "ec2-tunnel-key"
  public_key = tls_private_key.key_pair.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key_pair.private_key_pem
}

data "aws_ami" "ubuntu-linux-2004" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "public" {
  name        = "public"
  description = "public"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "public" {
  ami             = data.aws_ami.ubuntu-linux-2004.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.public.name]
  key_name        = aws_key_pair.key_pair.key_name
  user_data       = <<EOF
#!/bin/bash

echo "*******************initialized****************"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install net-tools -y
echo "GatewayPorts yes" >> /etc/ssh/sshd_config
sudo systemctl restart ssh
EOF

  tags = {
    Name = "public"
  }
}

resource "aws_security_group" "private" {
  name        = "private"
  description = "private"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "private" {
  ami             = data.aws_ami.ubuntu-linux-2004.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.private.name]
  key_name        = aws_key_pair.key_pair.key_name
  user_data       = <<EOF
#!/bin/bash

echo "*******************initialized****************"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install apache2 autossh net-tools -y
echo "*******************packages****************"
sudo systemctl restart apache2
sudo chmod 777 -R /var/www/html/
cd /var/www/html/
sudo echo "<h1>This is our test website deployed using Terraform.</h1>" > index.html
echo "*******************web****************"
cd /home/ubuntu
echo "${tls_private_key.key_pair.private_key_pem}" > key.pem
sudo chmod 600 key.pem
echo "*******************ssh key****************"
sudo autossh -M 20000 -N -i "key.pem" ubuntu@${aws_eip.public.public_ip} -R 8080:localhost:80 -oStrictHostKeyChecking=no -C
EOF  

  tags = {
    Name = "private"
  }
}

resource "aws_eip" "public" {
  instance = aws_instance.public.id
  vpc      = false
}
