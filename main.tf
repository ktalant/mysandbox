provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "talant_vpc" {
  cidr_block            = var.vpc_cidr
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = {
    Name = "main"
  }
}

