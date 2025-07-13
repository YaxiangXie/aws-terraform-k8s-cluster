variable "aws_availability_zone" {
  type    = string
  default = "ap-northeast-1a"
}

variable "awsinstance_type" {
  type = string
  default = "t2.medium"
}

variable "aws_key_name" {
  type = string
  default = "demo-key"
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "s3buckit_name" {
  type = string
  default = "yaxiang1"
}

variable "access_key" {
  description = "AWS access key from env"
  type        = string
  default     = ""  
}

variable "private_key" {
  description = "AWS secret key from env"
  type        = string
  default     = ""
}
