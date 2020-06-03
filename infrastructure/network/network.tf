/* This template is for provisioning of 
  VPC, Internet Gateway, Subnets, 
  NAT Gateway and Route Tables

  Variables used:
  networks
  project_name
  environment
*/

provider "aws" {
  profile = "terraform"
  region  = "ap-southeast-1"
}

resource "aws_vpc" "vpc" {
  cidr_block       = var.networks.cidr_block
  tags = {
    Name    = "${local.name_tag_prefix}-Vpc"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = {
    Name    = "${local.name_tag_prefix}-IGW"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${local.name_tag_prefix}-PublicRoute"
    Env     = var.environment
    Project = var.project_name

  }
}

resource "aws_subnet" "public" {
  count      = var.networks.public_subnets
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.networks.private_cidr_bits < var.networks.db_cidr_bits ? cidrsubnet(var.networks.cidr_block, var.networks.public_cidr_bits, var.networks.db_subnets * pow(2, var.networks.public_cidr_bits - var.networks.db_cidr_bits ) + pow(2, var.networks.public_cidr_bits - var.networks.private_cidr_bits) * var.networks.private_subnets + count.index) : cidrsubnet(var.networks.cidr_block, var.networks.public_cidr_bits, var.networks.private_subnets * pow(2, var.networks.public_cidr_bits - var.networks.private_cidr_bits) + pow(2, var.networks.public_cidr_bits - var.networks.db_cidr_bits ) * var.networks.db_subnets + count.index)
  # Distributes subnets in each AZ
  availability_zone_id = element(data.aws_availability_zones.azs.zone_ids, count.index)
  tags = {
    Name    = "${local.name_tag_prefix}-PublicSubnet${count.index+1}"
    Env     = var.environment
    Project = var.project_name
  }
}


resource "aws_route_table_association" "public" {
  count          = var.networks.public_subnets
  route_table_id = aws_route_table.public.id   
  subnet_id      = aws_subnet.public[count.index].id
}


resource "aws_eip" "nat" {
  count    = length(data.aws_availability_zones.azs.names) > var.networks.nat_gateways ? var.networks.nat_gateways : length(data.aws_availability_zones.azs.names)
  vpc      = true
  tags = {
    Name    = "${local.name_tag_prefix}-NatIp${count.index+1}"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(aws_eip.nat)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name    = "${local.name_tag_prefix}-NatGateway${count.index+1}"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_route_table" "private" {
  count  = length(aws_nat_gateway.nat)
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "${local.name_tag_prefix}-PrivateRoute${count.index+1}"
    Env     = var.environment
    Project = var.project_name

  }
}

resource "aws_subnet" "private" {
  count      = var.networks.private_subnets
  vpc_id     = aws_vpc.vpc.id
  # Starts from the last subnet in the public subnet. Sets up variable length subnetting
  cidr_block = var.networks.private_cidr_bits < var.networks.db_cidr_bits || var.networks.private_cidr_bits == var.networks.db_cidr_bits ? cidrsubnet(var.networks.cidr_block, var.networks.private_cidr_bits, count.index) : cidrsubnet(var.networks.cidr_block, var.networks.private_cidr_bits, var.networks.db_subnets * pow(2,var.networks.private_cidr_bits - var.networks.db_cidr_bits) + count.index)
  # Distributes subnets in each AZ
  availability_zone_id = element(data.aws_availability_zones.azs.zone_ids, count.index)
  tags = {
    Name    = "${local.name_tag_prefix}-PrivateSubnet${count.index+1}"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_route_table_association" "private" {
  count          = var.networks.private_subnets
  route_table_id = element(aws_route_table.private.*.id, count.index)
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_subnet" "db" {
  count      = var.networks.db_subnets
  vpc_id     = aws_vpc.vpc.id
  # Starts from the last subnet in the public subnet. Sets up variable length subnetting
  cidr_block = var.networks.db_cidr_bits < var.networks.private_cidr_bits || var.networks.private_cidr_bits == var.networks.db_cidr_bits ? cidrsubnet(var.networks.cidr_block, var.networks.db_cidr_bits, count.index) : cidrsubnet(var.networks.cidr_block, var.networks.db_cidr_bits, var.networks.private_subnets * pow(2,var.networks.db_cidr_bits - var.networks.private_cidr_bits) + count.index)
  # Distributes subnets in each AZ
  availability_zone_id = element(data.aws_availability_zones.azs.zone_ids, count.index)
  tags = {
    Name    = "${local.name_tag_prefix}-DbSubnet${count.index+1}"
    Env     = var.environment
    Project = var.project_name
  }
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.name_tag_prefix}-DbRoute"
    Env     = var.environment
    Project = var.project_name

  }
}

resource "aws_route_table_association" "db" {
  count          = var.networks.db_subnets
  route_table_id = element(aws_route_table.db.*.id, count.index)
  subnet_id      = aws_subnet.db[count.index].id
}
