variable "aws_region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "key1"
  type        =  string
  default     =  "key1"
}

variable "bucket_name" {
  description = "s3-bucket"
  type        = string
  default     = "race-bucket-project2"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for VPC Flow Logs"
  type        = string
  default     = "vpc-flow-log-vignesh-reva"
}

variable "vpc_ids" {
  description = "List of VPC IDs to target for flow logs"
  type        = list(string)
  default     = []
}

variable "s3_bucket_ids" {
  description = "List of S3 buckets to enforce versioning"
  type        = list(string)
  default     = []
}
