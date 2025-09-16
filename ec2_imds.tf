# Get all EC2 instances
data "aws_instances" "all" {}

# Enforce IMDSv2 for each EC2 instance
resource "aws_instance_metadata_defaults" "imds" {
  http_tokens                 = "required"
  http_endpoint               = "enabled"
  http_put_response_hop_limit = 1
}
