provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "config_bucket" {
  bucket = "cis-bucket"
  acl    = "private"
}

resource "aws_iam_role" "config_role" {
  name = "ConfigRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_role_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_configuration_recorder" "main" {
  name     = "main"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "main"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
}

# IAM related Config Rules
resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"
  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }
}

resource "aws_config_config_rule" "iam_mfa_enabled_for_root" {
  name = "iam-root-mfa-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
}

# S3 related Config Rules
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

resource "aws_config_config_rule" "s3_bucket_logging_enabled" {
  name = "s3-bucket-logging-enabled"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LOGGING_ENABLED"
  }
}

# VPC related Config Rules
resource "aws_config_config_rule" "vpc_default_security_group_restricted" {
  name = "vpc-default-security-group-restricted"
  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_RESTRICTED"
  }
}

resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  name = "vpc-flow-logs-enabled"
  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }
}

# EC2 related Config Rules
resource "aws_config_config_rule" "ec2_managed_instance_inventory" {
  name = "ec2-managed-instance-inventory"
  source {
    owner             = "AWS"
    source_identifier = "EC2_MANAGED_INSTANCE_INVENTORY"
  }
}

resource "aws_config_config_rule" "ec2_instance_managed_by_ssm" {
  name = "ec2-instance-managed-by-ssm"
  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_MANAGED_BY_SSM"
  }
}

# ALB related Config Rules
resource "aws_config_config_rule" "elb_authentication_policy_exists" {
  name = "elb-authentication-policy-exists"
  source {
    owner             = "AWS"
    source_identifier = "ELB_AUTHENTICATION_POLICY_EXISTS"
  }
}

resource "aws_config_config_rule" "alb_http_to_https_redirect" {
  name = "alb-http-to-https-redirect"
  source {
    owner             = "AWS"
    source_identifier = "ALB_HTTP_TO_HTTPS_REDIRECT"
  }
}
# NLB related Config Rules
resource "aws_config_config_rule" "nlb_cross_zone_enabled" {
  name = "nlb-cross-zone-enabled"
  source {
    owner             = "AWS"
    source_identifier = "NLB_CROSS_ZONE_ENABLED"
  }
}
