terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "TF1" {
  ami             = "ami-080e1f13689e07408"
  instance_type   = "t2.micro"
  key_name        = "my-aws-keypair"
  security_groups = ["ssh-and-my-echo-server"]

  tags = {
    Name = "HOPE-FOR-EAST"
  }
}

resource "aws_ec2_instance_state" "TF1" {
  instance_id = aws_instance.TF1.id
  state       = "running"
}
