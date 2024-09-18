variable "aws_profile" {
  
}

variable "aws_region" {
  
}

variable "ou_names" {
  type = list(string)
}

variable "accounts" {
  type = map(object({
    email = string
    ou    = string
  }))
}

variable "s3_bucket_name" {
  type        = string
  description = "The name of the S3 bucket for centralized logging."
}
