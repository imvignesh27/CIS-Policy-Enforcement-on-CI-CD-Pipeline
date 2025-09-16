# EC2 IMDSv2 Enforcement
resource "aws_instance_metadata_defaults" "enforce_imdsv2" {
  http_tokens   = "required"
  http_endpoint = "enabled"
}

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  for_each = toset(var.vpc_ids)

  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.flow_logs_bucket.arn
  traffic_type         = "ALL"
  vpc_id               = each.value

  depends_on = [aws_s3_bucket.flow_logs_bucket]
}

# S3 Bucket for Flow Logs
resource "aws_s3_bucket" "flow_logs_bucket" {
  bucket = "${var.prefix}-flowlogs-${random_id.suffix.hex}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Enable Versioning on Non-Compliant Buckets
resource "aws_s3_bucket_versioning" "enforce_versioning" {
  for_each = toset(var.s3_bucket_ids)

  bucket = each.value
  versioning_configuration {
    status = "Enabled"
  }
}

