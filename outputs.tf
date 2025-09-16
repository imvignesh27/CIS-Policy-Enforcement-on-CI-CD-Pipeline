output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

output "nlb_dns" {
  value = aws_lb.app_nlb.dns_name
}

output "config_bucket_name" {
  value = aws_s3_bucket.config_logs.bucket
}

output "config_recorder_name" {
  value = aws_config_configuration_recorder.main.name
}

output "iam_role_arn" {
  value = aws_iam_role.config_role.arn
}

output "flow_logs_bucket" {
  value = aws_s3_bucket.flow_logs.bucket
}

output "flow_logs_role" {
  value = aws_iam_role.flow_logs_role.arn
}

output "enabled_vpc_flow_logs" {
  value = { for k, v in aws_flow_log.vpc : k => v.id }
}
