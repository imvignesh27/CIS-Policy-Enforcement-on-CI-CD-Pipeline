provider "aws" {
  region = "ap-south-1"
}

# Generate a unique suffix for resource names
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 bucket for AWS Config logs
resource "aws_s3_bucket" "config_logs" {
  bucket = "cis-config-logs-${random_id.suffix.hex}"

  tags = {
    Project = "CIS-Compliance"
    Owner   = "SecurityTeam"
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "config_logs_versioning" {
  bucket = aws_s3_bucket.config_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption on the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "config_logs_encryption" {
  bucket = aws_s3_bucket.config_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Optional: Add lifecycle rule to expire logs after 365 days
resource "aws_s3_bucket_lifecycle_configuration" "config_logs_lifecycle" {
  bucket = aws_s3_bucket.config_logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days = 365
    }
  }
}

# IAM role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "cis-config-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "config.amazonaws.com"
      }
    }]
  })

  tags = {
    Project = "CIS-Compliance"
    Owner   = "SecurityTeam"
  }
}

# Attach AWS Config managed policy to the role
resource "aws_iam_role_policy_attachment" "config_policy_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# AWS Config recorder with global resource recording enabled
resource "aws_config_configuration_recorder" "main" {
  name     = "cis-recorder-${random_id.suffix.hex}"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Delivery channel for AWS Config
resource "aws_config_delivery_channel" "main" {
  name           = "cis-delivery-${random_id.suffix.hex}"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket

  depends_on = [aws_config_configuration_recorder.main]
}

# Enable the configuration recorder (after delivery channel exists)
resource "aws_config_configuration_recorder_status" "enabled" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# List of AWS Managed CIS Config rules
locals {
  config_rules = [
    "IAM_PASSWORD_POLICY",
    "IAM_USER_MFA_ENABLED",
    "IAM_ROOT_ACCESS_KEY_CHECK",
    "S3_BUCKET_PUBLIC_READ_PROHIBITED",
    "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED",
    "S3_BUCKET_VERSIONING_ENABLED",
    "EC2_INSTANCE_NO_PUBLIC_IP",
    "EC2_EBS_ENCRYPTION_BY_DEFAULT",
    "EC2_INSTANCE_DETAILED_MONITORING_ENABLED",
    "VPC_FLOW_LOGS_ENABLED",
    "VPC_DEFAULT_SECURITY_GROUP_CLOSED",
    "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS",
    "ALB_WAF_ENABLED",
    "ALB_HTTP_TO_HTTPS_REDIRECTION_CHECK",
    "ELBV2_LOGGING_ENABLED",
    "NLB_CROSS_ZONE_LOAD_BALANCING_ENABLED",
    "NLB_LOGGING_ENABLED",
    "NLB_INTERNAL_SCHEME_CHECK"
  ]
}

# Create AWS Config rules dynamically
resource "aws_config_config_rule" "cis_rules" {
  for_each = toset(local.config_rules)

  name = lower(each.key)
  source {
    owner             = "AWS"
    source_identifier = each.key
  }

  depends_on = [aws_config_configuration_recorder_status.enabled]

  tags = {
    Project = "CIS-Compliance"
    Owner   = "SecurityTeam"
  }
}
