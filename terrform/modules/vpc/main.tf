resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_a_cidr
  availability_zone = var.az_a
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_b_cidr
  availability_zone = var.az_b
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-b"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_a_cidr
  availability_zone = var.az_a
  tags = {
    Name = "${var.vpc_name}-private-a"
  }
}
