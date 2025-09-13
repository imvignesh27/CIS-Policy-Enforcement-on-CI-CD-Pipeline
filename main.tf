# Fetch available AZs
data "aws_availability_zones" "available" {}

# IAM Role & Policy
resource "aws_iam_role" "ec2_role" {
  name = "ec2_basic_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name   = "ec2_basic_policy"
  role   = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["s3:ListBucket", "s3:GetObject"],
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

# S3 Bucket
resource "aws_s3_bucket" "app_bucket" {
  bucket = var.bucket_name
  acl    = "private"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "20.0.0.0/16"
}

# Subnets in two AZs
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "20.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "20.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = "ami-0b9093ea00a0fed922"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_a.id
  key_name               = var.key_name
  security_groups        = [aws_security_group.web_sg.name]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "Jenkins-Terraform-EC2"
  }
}

# ALB
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  security_groups    = [aws_security_group.web_sg.id]
}

# ALB Target Group
resource "aws_lb_target_group" "alb_tg" {
  name        = "alb-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
}

# ALB Listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

# ALB Target Attachment
resource "aws_lb_target_group_attachment" "alb_attachment" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

# NLB
resource "aws_lb" "app_nlb" {
  name               = "app-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

# NLB Target Group
resource "aws_lb_target_group" "nlb_tg" {
  name        = "nlb-target-group"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
}

# NLB Listener
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.app_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}

# NLB Target Attachment
resource "aws_lb_target_group_attachment" "nlb_attachment" {
  target_group_arn = aws_lb_target_group.nlb_tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

# Detect AWS Config rule
#IAM
resource "aws_config_config_rule" "iam_root_access_key_check" {
  name = "iam-root-access-key-check"
  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }
}

resource "aws_config_config_rule" "access_keys_rotated" {
  name = "access-keys-rotated"
  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }
}

#S3 rule
resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

resource "aws_config_config_rule" "s3_encryption_enabled" {
  name = "s3-bucket-server-side-encryption-enabled"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}

#VPC rule
resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  name = "vpc-flow-logs-enabled"
  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }
}

resource "aws_config_config_rule" "vpc_default_sg_closed" {
  name = "vpc-default-security-group-closed"
  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }
}

#EC2 Rule
resource "aws_config_config_rule" "ec2_no_public_ip" {
  name = "ec2-instance-no-public-ip"
  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_NO_PUBLIC_IP"
  }
}

resource "aws_config_config_rule" "ec2_imdsv2_check" {
  name = "ec2-imdsv2-check"
  source {
    owner             = "AWS"
    source_identifier = "EC2_IMDSV2_CHECK"
  }
}

# ALB rule

resource "aws_config_config_rule" "alb_https_listener" {
  name = "alb-https-listeners"
  source {
    owner             = "AWS"
    source_identifier = "ALB_HTTPS_LISTENERS"
  }
}

resource "aws_config_config_rule" "alb_logging_enabled" {
  name = "alb-logging-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ALB_LOGGING_ENABLED"
  }
}

#NLB rule
resource "aws_config_config_rule" "nlb_cross_zone_enabled" {
  name = "nlb-cross-zone-load-balancing-enabled"
  source {
    owner             = "AWS"
    source_identifier = "NLB_CROSS_ZONE_LOAD_BALANCING_ENABLED"
  }
}

resource "aws_config_config_rule" "nlb_logging_enabled" {
  name = "nlb-logging-enabled"
  source {
    owner             = "AWS"
    source_identifier = "NLB_LOGGING_ENABLED"
  }
}
