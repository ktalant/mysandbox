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

resource "aws_default_route_table" "public_rt" {
  default_route_table_id = aws_vpc.talant_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "talant-public-RouteTable"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "10.0.0.0/16"
  }

  tags = {
    Name = "talant-private-RouteTable"
  }
}



