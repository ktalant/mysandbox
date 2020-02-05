provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

#--------------------------PART2 - New VPC Creation--------------------------
# VPC
resource "aws_vpc" "talant_vpc" {
  cidr_block            = var.vpc_cidr
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = {
    Name = "talant-VPC"
  }
}
#--------------------------PART2 - IGW, Public Subnet, Public Subnet Association--------------------------
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.talant_vpc.id

  tags = {
    Name = "talant-IGW"
  }
}

# Public Route Table
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

# Public Subnets
resource "aws_subnet" "talant_public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.talant_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "talant_public_subnet${count.index + 1}"
  }
}

# Public Subnet association
resource "aws_route_table_association" "talant_public_assoc" {
  count          = length(aws_subnet.talant_public_subnet)
  subnet_id      = aws_subnet.talant_public_subnet.*.id[count.index]
  route_table_id = aws_default_route_table.public_rt.id
}

#--------------------------PART3 - ElasticIp, NatGW, Private Subnet, Private Subnet Association--------------------
# Elastic IP for Nat gateway
resource "aws_eip" "talant_eip" {
  vpc = true
  depends_on                = [aws_internet_gateway.igw]
}

# Nat Gateway
resource "aws_nat_gateway" "talant_ngw" {
  allocation_id = aws_eip.talant_eip.id
  subnet_id     = aws_subnet.talant_public_subnet.*.id[0]

  tags = {
    Name = "talant-NATGW"
  }
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.talant_vpc.id

  route {
    destination_cidr_block    = "10.0.1.0/24"
    nat_gateway_id = aws_nat_gateway.talant_ngw.id
  }

  tags = {
    Name = "talant-private-RouteTable"
  }
}

# Private Subnet
resource "aws_subnet" "talant_private_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.talant_vpc.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "talant_private_subnet${count.index + 1}"
  }
}


# Private Subnet association
resource "aws_route_table_association" "talant_private_assoc" {
  count          = length(aws_subnet.talant_private_subnet)
  subnet_id      = aws_subnet.talant_private_subnet.*.id[count.index]
  route_table_id = aws_route_table.private_rt.id
}





