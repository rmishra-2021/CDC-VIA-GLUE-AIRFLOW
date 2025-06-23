provider "aws" {
  region = "us-east-1"
}

# ========== VARIABLES ==========
variable "vpc_id" {
  description = "The VPC ID where the subnets exist"
  default     = "vpc-xxxxxxxxxxxxxxx"  # Replace with your actual VPC ID
}

# Subnet-0: Public Subnet to host NAT Gateway
variable "public_subnet_for_nat" {
  default = "subnet-xxxxxxxxxxxxxxx"
}

# Subnet-1: Private Subnet to attach NAT
variable "subnet_to_be_private1" {
  default = "subnet-xxxxxxxxxxxxxxx"
}

# Subnet-2: Private Subnet to attach NAT
variable "subnet_to_be_private2" {
  default = "subnet-xxxxxxxxxxxxxxx"
}

# ========== ELASTIC IP for NAT GATEWAY ==========
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-gateway-eip"
  }
}

# ========== NAT GATEWAY ==========
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = var.public_subnet_for_nat

  tags = {
    Name = "public-nat-gateway"
  }

  depends_on = [aws_eip.nat_eip]
}

# ========== PRIVATE ROUTE TABLE ==========
resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# ========== ASSOCIATE PRIVATE ROUTE TABLE ==========
resource "aws_route_table_association" "make_subnet_private1" {
  subnet_id      = var.subnet_to_be_private1
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "make_subnet_private2" {
  subnet_id      = var.subnet_to_be_private2
  route_table_id = aws_route_table.private_rt.id
}


