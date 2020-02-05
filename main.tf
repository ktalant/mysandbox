provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "talant_vpc" {
  cidr_block            = var.vpc_cidr
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = {
    Name = "talant-VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.talant_vpc.id

  tags = {
    Name = "talant-IGW"
  }
}



