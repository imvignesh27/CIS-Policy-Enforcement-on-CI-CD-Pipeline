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
