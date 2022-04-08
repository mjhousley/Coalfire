# Create VPC
resource "aws_vpc" "Coalfire VPC" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "Coalfire VPC"
    Environment = var.app_environment
  }
}

# Create Public Subnets
resource "aws_subnet" "public-subnets" {
  count                   = var.item_count
  vpc_id                  = aws_vpc.cf-vpc.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet ${count.index + 1}"
    Environment = var.app_environment
  }
}


# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.cf-vpc.id
  tags = {
    Name = "clientapp.com IGW"
    Environment = var.app_environment
  }
}

# Create Route Table for public subnets
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.cf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
    Environment = var.app_environment
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "route-table-association" {
  count          = var.item_count
  subnet_id      = aws_subnet.public-subnets[count.index].id
  route_table_id = aws_route_table.public-rt.id
}


# Create WP Private Subnet
resource "aws_subnet" "wp-private-subnets" {
  count                   = var.item_count
  vpc_id                  = aws_vpc.cf-vpc.id
  cidr_block              = var.WP_private_subnet_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "WP Subnet ${count.index + 1}"
    Environment = var.app_environment
  }
}

# Create Route Table for wp-private-subnets subnets
resource "aws_route_table" "wpsubnet-rt" {
  vpc_id = aws_vpc.cf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "wp-private-subnets Route Table"
    Environment = var.app_environment
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "wp-private-subnet-route-table-association" {
  count          = var.item_count
  subnet_id      = aws_subnet.wp-private-subnets[count.index].id
  route_table_id = aws_route_table.public-rt.id
}

# Create DB Private Subnet
resource "aws_subnet" "db-private-subnets" {
  count                   = var.item_count
  vpc_id                  = aws_vpc.cf-vpc.id
  cidr_block              = var.DB_private_subnet_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "DB Subnet ${count.index + 1}"
  }
}