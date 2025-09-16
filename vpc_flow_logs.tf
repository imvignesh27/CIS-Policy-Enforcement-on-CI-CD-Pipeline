# Get all VPCs
data "aws_vpcs" "all" {}

# S3 bucket for VPC Flow Logs
resource "aws_s3_bucket" "flow_logs" {
  bucket = var.s3_bucket_name
  acl    = "private"

  tags = {
    Name      = "vpc-flow-logs-bucket"
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.flow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for Flow Logs
resource "aws_iam_role" "flow_logs_role" {
  name = "tf_vpc_flow_logs_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs_s3_policy" {
  name = "tf_vpc_flow_logs_s3_policy"
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:PutObject", "s3:GetBucketAcl", "s3:ListBucket"],
      Resource = [
        "${aws_s3_bucket.flow_logs.arn}",
        "${aws_s3_bucket.flow_logs.arn}/*"
      ]
    }]
  })
}

# Flow logs for each VPC
resource "aws_flow_log" "vpc" {
  for_each             = toset(data.aws_vpcs.all.ids)
  resource_id          = each.key
  resource_type        = "VPC"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::${aws_s3_bucket.flow_logs.bucket}"
  iam_role_arn         = aws_iam_role.flow_logs_role.arn

  tags = {
    Name = "flow-log-${each.key}"
  }
}
