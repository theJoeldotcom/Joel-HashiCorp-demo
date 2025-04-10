terraform {
   required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "demo" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "hashicorp-demo"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.demo.id
  cidr_block = "10.0.2.0/24"

    tags = {
      Name = "private-1"
    }
}

resource "aws_internet_gateway" "demo-IGW" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "demo-IGW"
  }
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-IGW.id
  }
  tags = {
    Name = "Public route"
  }
}

resource "aws_route_table_association" "public-route" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.route.id
}