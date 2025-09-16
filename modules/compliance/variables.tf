variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
  default     = "cis-remediation"
}

variable "vpc_ids" {
  description = "List of VPC IDs to enable flow logs on"
  type        = list(string)
  default     = []
}

variable "s3_bucket_ids" {
  description = "List of S3 bucket names that require versioning"
  type        = list(string)
  default     = []
}
