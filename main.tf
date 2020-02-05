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
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "talant-NATGW"
  }
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.talant_vpc.id

  tags = {
    Name = "talant-private-RouteTable"
  }
}

resource "aws_route" "private_nat_gateway_route" {
  route_table_id = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on = [aws_route_table.private_rt]
  nat_gateway_id = aws_nat_gateway.talant_ngw.id
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
#--------------------------PART4 - Security Groups--------------------
# Bastion Host Sec-Group
resource "aws_security_group" "bastion_sg" {
  name        = "allow_tls"
  description = "Allow SSH inbound traffic from VPN cidr"
  vpc_id      = aws_vpc.talant_vpc.id

  ingress {
    # SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_vpn_cidr
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
#--------------------------PART4 - KeyPairs, Bastion Host in Public Subnet  --------------------
# Ami id (ubuntu in this specific example)
# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }
# KeyPair
resource "aws_key_pair" "deployer" {
  key_name   = "bastionkey"
  public_key = file(var.key_path)
}



# Instance
resource "aws_instance" "web" {
  # ami                       = data.aws_ami.ubuntu.id
  ami                           = var.ami_id
  instance_type                 = var.instance_type
  subnet_id                     = aws_subnet.talant_public_subnet.*.id[1]
  security_groups               = [aws_security_group.bastion_sg.id]
  associate_public_ip_address   = true

  tags = {
    Name = "talant-BastionHost"
  }
}



