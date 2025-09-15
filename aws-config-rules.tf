provider "aws" {
  region = "ap-south-1"
}

# S3 bucket for Config logs
resource "aws_s3_bucket" "config_logs" {
  bucket = "my-config-logs-race-casptone" # CHANGE this to a unique name
}

# AWS Config IAM role and policy
resource "aws_iam_role" "config_role" {
  name = "aws-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

# Config Recorder and Channel
resource "aws_config_configuration_recorder" "main" {
  name     = "main"
  role_arn = aws_iam_role.config_role.arn
}

resource "aws_config_delivery_channel" "main" {
  name           = "main"
  s3_bucket_name = aws_s3_bucket.config_logs.bucket
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "enabled" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
}

# IAM Rules
resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"
  source { owner = "AWS" source_identifier = "IAM_PASSWORD_POLICY" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "iam_user_mfa_enabled" {
  name = "iam-user-mfa-enabled"
  source { owner = "AWS" source_identifier = "IAM_USER_MFA_ENABLED" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "iam_root_access_key_check" {
  name = "iam-root-access-key-check"
  source { owner = "AWS" source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK" }
  depends_on = [aws_config_delivery_channel.main]
}

# S3 Rules
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"
  source { owner = "AWS" source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "s3_bucket_server_side_encryption_enabled" {
  name = "s3-bucket-server-side-encryption-enabled"
  source { owner = "AWS" source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "s3_bucket_versioning_enabled" {
  name = "s3-bucket-versioning-enabled"
  source { owner = "AWS" source_identifier = "S3_BUCKET_VERSIONING_ENABLED" }
  depends_on = [aws_config_delivery_channel.main]
}

# EC2 Rules
resource "aws_config_config_rule" "ec2_instance_no_public_ip" {
  name = "ec2-instance-no-public-ip"
  source { owner = "AWS" source_identifier = "EC2_INSTANCE_NO_PUBLIC_IP" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "ec2_ebs_encryption_by_default" {
  name = "ec2-ebs-encryption-by-default"
  source { owner = "AWS" source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "ec2_instance_detailed_monitoring_enabled" {
  name = "ec2-instance-detailed-monitoring-enabled"
  source { owner = "AWS" source_identifier = "EC2_INSTANCE_DETAILED_MONITORING_ENABLED" }
  depends_on = [aws_config_delivery_channel.main]
}

# VPC Rules
resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  name = "vpc-flow-logs-enabled"
  source { owner = "AWS" source_identifier = "VPC_FLOW_LOGS_ENABLED" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "vpc_default_security_group_closed" {
  name = "vpc-default-security-group-closed"
  source { owner = "AWS" source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "vpc_sg_open_only_to_authorized_ports" {
  name = "vpc-sg-open-only-to-authorized-ports"
  source { owner = "AWS" source_identifier = "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS" }
  depends_on = [aws_config_delivery_channel.main]
}

# ALB Rules
resource "aws_config_config_rule" "alb_waf_enabled" {
  name = "alb-waf-enabled"
  source { owner = "AWS" source_identifier = "ALB_WAF_ENABLED" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "alb_http_to_https_redirection_check" {
  name = "alb-http-to-https-redirection-check"
  source { owner = "AWS" source_identifier = "ALB_HTTP_TO_HTTPS_REDIRECTION_CHECK" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "alb_logging_enabled" {
  name = "alb-logging-enabled"
  source { owner = "AWS" source_identifier = "ELBV2_LOGGING_ENABLED" }
  depends_on = [aws_config_delivery_channel.main]
}

# NLB Rules
resource "aws_config_config_rule" "nlb_cross_zone_load_balancing_enabled" {
  name = "nlb-cross-zone-load-balancing-enabled"
  source { owner = "AWS" source_identifier = "NLB_CROSS_ZONE_LOAD_BALANCING_ENABLED" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "nlb_logging_enabled" {
  name = "nlb-logging-enabled"
  source { owner = "AWS" source_identifier = "NLB_LOGGING_ENABLED" }
  depends_on = [aws_config_delivery_channel.main]
}
resource "aws_config_config_rule" "nlb_internal_scheme_check" {
  name = "nlb-internal-scheme-check"
  source { owner = "AWS" source_identifier = "NLB_INTERNAL_SCHEME_CHECK" }
  depends_on = [aws_config_delivery_channel.main]
}
