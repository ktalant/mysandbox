provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "example" {
  most_recent      = true


  filter {
    name   = "name"
    values = ["Centos 7-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
