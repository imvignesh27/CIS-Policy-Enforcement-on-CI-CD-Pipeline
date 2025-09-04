provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "race" {
  cidr_block = "100.0.0.0/16"
  tags = {
    Name = "race-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "100.0.10.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "100.0.20.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "public-subnet-b"
  }
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow web, SSH, HTTPS, and RDP"
  vpc_id      = aws_vpc.race.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "web-admin" {
  name = "dev-admin-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "race-bucket"
  acl    = "public"
}

resource "aws_instance" "web-server" {
  ami                    = "ami-0c94855ba95c71c99" # Update to a valid AMI for your region
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_role.web-server.name
  tags = {
    Name = "web-server"
  }
}

resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.web.id]
}

resource "aws_lb" "web_nlb" {
  name               = "web-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  # NLB does not support security groups
}
