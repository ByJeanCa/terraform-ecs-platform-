variable "region" {
  type        = string
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
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
}

variable "app_name" {
  type = string
}