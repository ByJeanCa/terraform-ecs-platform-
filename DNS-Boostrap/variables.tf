variable "region" {
  type        = string
  description = "AWS region"
  default = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
  default = "dev"
}

variable "common_tags" {
  type = map(string)
  default = {
    Project   = "Terraform-ECS-Platform"
    Owner     = "Jean"
    Managedby = "Terraform"
  }
  description = "Base tags to merge into all resources"
}

variable "domain" {
  type = string
  default = "veliacr.com"
}

variable "app_name" {
  type = string
  default = "test"
}

variable "email" {
  type = string
  description = "Email to send to notify about CloudWatch Alarms"
  default = "jo7624822@gmnail.com"
}
