variable "region" {
  type        = string
  description = "AWS region"
  default = "us-east-1"
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
