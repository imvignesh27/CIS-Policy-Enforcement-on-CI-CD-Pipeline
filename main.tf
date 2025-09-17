#======== provider ==========#

provider "aws" {
  region = "ap-south-1"
}

#===========  IAM USER  ==========#

module "iam_user" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

  name = "terra.user1"

  force_destroy           = true
  pgp_key                 = "keybase:test"
  password_reset_required = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

#==========  VPC  ===========#

resource "aws_vpc" "new_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "new_vpc"
  }
}

resource "aws_internet_gateway" "new_igw" {
  vpc_id = aws_vpc.new_vpc.id
  tags = {
    Name = "new-internet-gateway"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.new_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a" 
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.new_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "private_subnet"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.new_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.new_vpc.id
}

resource "aws_eip" "nat_eip" {
  # allocation_id or association arguments depending on use case
  tags = {
    Name = "nat-eip"
  }
}


resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "my_nat_gateway"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

#=======  Security Groups ===========#

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.new_vpc.id
  tags = {
    Name = "private_sg"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }
}

resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.new_vpc.id
  tags = {
    Name = "public_sg"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#======  S3  ======#

resource "aws_s3_bucket" "my_bucket" {
  bucket = "new-vignesh-bucket"
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "public-read"
}

#==========  EC2  =============#

resource "aws_instance" "ubuntu-server" {
  ami           = "ami-0f2e255ec956ade7f"
  instance_type = "t2.micro"              

  tags = {
    Name = "UbuntuServer"
  }
}

