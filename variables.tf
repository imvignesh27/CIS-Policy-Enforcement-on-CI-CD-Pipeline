variable "aws_region" {
  default = "us-east-1"
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
