output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

output "nlb_dns" {
  value = aws_lb.app_nlb.dns_name
}
