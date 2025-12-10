variable "region" {
  type = string
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
}

variable "az_count" {
  type        = number
  default     = 2
  description = "How many AZs to use (2 recommended)"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Base tags to merge into all resources"
}

variable "newbits" {
  type        = number
  default     = 8
  description = "VPC CIDR mask + newbits to subnets mask"
}

