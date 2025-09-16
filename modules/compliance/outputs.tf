output "flow_logs_bucket" {
  description = "The S3 bucket used for storing VPC flow logs"
  value       = aws_s3_bucket.flow_logs_bucket.bucket
}
