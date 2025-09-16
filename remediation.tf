# IMDSv2 remediation
resource "aws_ec2_instance_metadata_options" "fix_imds" {
  for_each      = toset(data.external.noncompliant_ec2.result)
  instance_id   = each.value
  http_tokens   = "required"
  http_endpoint = "enabled"
}

# VPC Flow Logs remediation
resource "aws_flow_log" "fix_vpc_flow_logs" {
  for_each             = toset(data.external.noncompliant_vpcs.result)
  resource_id          = each.value
  resource_type        = "VPC"
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "arn:aws:s3:::${aws_s3_bucket.flow_logs.bucket}"
  iam_role_arn         = aws_iam_role.flow_logs_role.arn

  tags = {
    Name = "remediated-flow-log-${each.value}"
  }
}
