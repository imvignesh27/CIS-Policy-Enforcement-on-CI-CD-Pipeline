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

# Enable the configuration recorder
resource "aws_config_configuration_recorder_status" "enabled" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# ------------------------
# Config Rules (Only 2)
# ------------------------

# Rule 1: EC2 instances must use IMDSv2
resource "aws_config_config_rule" "ec2_imds" {
  name = "ec2-imdsv2-check"

  source {
    owner             = "AWS"
    source_identifier = "EC2_IMDSV2_CHECK"
  }

  depends_on = [aws_config_configuration_recorder_status.enabled]

  tags = {
    Project = "CIS-Compliance"
    Owner   = "SecurityTeam"
  }
}

# Rule 2: VPCs must have flow logs enabled
resource "aws_config_config_rule" "vpc_flow_logs" {
  name = "vpc-flow-logs-enabled"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.enabled]

  tags = {
    Project = "CIS-Compliance"
    Owner   = "SecurityTeam"
  }
}
