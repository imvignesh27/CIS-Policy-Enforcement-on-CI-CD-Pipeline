locals {
  cis_config_rules = [
    // IAM
    { name = "iam-password-policy",                  source_id = "IAM_PASSWORD_POLICY" },
    { name = "iam-root-mfa-enabled",                 source_id = "ROOT_ACCOUNT_MFA_ENABLED" },
    // S3
    { name = "s3-bucket-public-read-prohibited",     source_id = "S3_BUCKET_PUBLIC_READ_PROHIBITED" },
    { name = "s3-bucket-logging-enabled",            source_id = "S3_BUCKET_LOGGING_ENABLED" },
    // VPC
    { name = "vpc-default-security-group-restricted",source_id = "VPC_DEFAULT_SECURITY_GROUP_RESTRICTED" },
    { name = "vpc-flow-logs-enabled",                source_id = "VPC_FLOW_LOGS_ENABLED" },
    // EC2
    { name = "ec2-managed-instance-inventory",       source_id = "EC2_MANAGED_INSTANCE_INVENTORY" },
    { name = "ec2-instance-managed-by-ssm",          source_id = "EC2_INSTANCE_MANAGED_BY_SSM" },
    // ALB
    { name = "alb-http-to-https-redirect",           source_id = "ALB_HTTP_TO_HTTPS_REDIRECT" },
    { name = "elb-authentication-policy-exists",     source_id = "ELB_AUTHENTICATION_POLICY_EXISTS" }
  ]
}

resource "aws_config_config_rule" "cis" {
  for_each = { for rule in local.cis_config_rules : rule.name => rule }
  name     = each.value.name
  source {
    owner             = "AWS"
    source_identifier = each.value.source_id
  }
}
