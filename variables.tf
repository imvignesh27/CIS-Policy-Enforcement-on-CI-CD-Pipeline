variable "aws_region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "key1"
  type        = string
}

variable "bucket_name" {
  description = "race-bucket-project2"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for VPC Flow Logs"
  type        = string
  default     = "vpc-flow-log-vignesh-reva"
}
