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

# VPC

resource "aws_vpc" "demo" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "hashicorp-demo"
  }
}

#Subnets

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id = aws_vpc.demo.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2c"
  tags = {
    Name = "public-2"
  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.demo.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  tags = {
      Name = "private-1"
    }
}

resource "aws_subnet" "private2" {
  vpc_id = aws_vpc.demo.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-west-2c"
  tags = {
      Name = "private-2"
    }
}

#Route Tables

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

resource "aws_route_table_association" "public-route2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.route.id
}

resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.demo.id

  route {

  }
}


#IGW

resource "aws_internet_gateway" "demo-IGW" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "demo-IGW"
  }
}

#NAT Gateway

resource "aws_nat_gateway" "demo-NATGW" {
  allocation_id = aws_eip.EIP-NAT.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "NAT-GW"
  }

  depends_on = [aws_internet_gateway.demo-IGW]
}

#EIP

resource "aws_eip" "EIP-NAT" {
  vpc = true
}


#Scurity groups

resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow 80 and 443 inbound traffic, and all outbound traffic"
  vpc_id      = aws_vpc.demo.id

  tags = {
    Name = "web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "TLS_443" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "HTTP_80" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#EC2 instances
# ami-0a9841b43a830391e

resource "aws_instance" "webserver" {
  ami = "ami-0a9841b43a830391e"
  instance_type = "t3a.small"
  key_name = "AWS-dev"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  associate_public_ip_address = true
  tags = {
    Name = "Webserver"
  }
}

resource "aws_instance" "webserver2" {
  ami = "ami-0a9841b43a830391e"
  instance_type = "t3a.small"
  key_name = "AWS-dev"
  subnet_id = aws_subnet.public2.id
  vpc_security_group_ids = [aws_security_group.web.id]
  associate_public_ip_address = true
  tags = {
    Name = "Webserver2"
  }
}

#ELB

resource "aws_lb" "ELB-public" {
  name               = "ELB-public"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public2.id]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "webservers" {
  name     = "webservers"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo.id
}

resource "aws_lb_target_group_attachment" "target-group-attachment" {
  target_group_arn = aws_lb_target_group.webservers.arn
  target_id        = aws_instance.webserver.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "target-group-attachment2" {
  target_group_arn = aws_lb_target_group.webservers.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

resource "aws_lb_listener" "public-listener" {
  load_balancer_arn = aws_lb.ELB-public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type            = "forward"
    target_group_arn = aws_lb_target_group.webservers.arn
  }
}

/*
resource "aws_s3_bucket" "demo-bucket" {
  bucket = "thejoel-hashicorp-demo"

  tags = {
    Name        = "demo-bucket"
    Environment = "demo"
  }
}
*/

