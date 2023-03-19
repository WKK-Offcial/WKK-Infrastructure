terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.50"
    }
  }

  required_version = ">= 1.4"
}

provider "aws" {
  region = "eu-central-1"
}

resource "tls_private_key" "ec2_ssh_key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "ec2_ssh_key" {
  key_name   = "ec2_ssh_key"
  public_key = tls_private_key.ec2_ssh_key.public_key_openssh
}

resource "aws_instance" "boi_bot" {
  ami           = data.aws_ami.ec2_ami.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.public.id]
  key_name      = aws_key_pair.ec2_ssh_key.key_name
  user_data     = <<FILE
  #!/bin/bash
  IFS=',' read -r -a ssh_array <<< "${join(",", var.ec2_ssh_public_keys)}"
  for ssh_key in "$${ssh_array[@]}"; do
  echo "$ssh_key" >> /home/ec2-user/.ssh/authorized_keys
  done
  FILE

  tags = {
    Name = "WKK-Bot"
  }
}


resource "aws_security_group" "public" {
  name = "wkk-${var.infra_env}-public-sg"
  description = "Public internet access"
  vpc_id = aws_vpc.vpc.id
 
  tags = {
    Name        = "wkk-${var.infra_env}-public-sg"
    Role        = "public"
    ManagedBy   = "terraform"
  }
}
 
resource "aws_security_group_rule" "public_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 
  security_group_id = aws_security_group.public.id
}
 
resource "aws_security_group_rule" "public_in_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
}
 
resource "aws_security_group_rule" "public_in_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
}
 
resource "aws_security_group_rule" "public_in_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
}

data "aws_ami" "ec2_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
}
