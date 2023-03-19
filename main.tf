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
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
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

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}