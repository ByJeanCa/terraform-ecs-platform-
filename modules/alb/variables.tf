variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Base tags to merge into all resources"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
}

variable "region" {
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "subnets" {
  type = list(string)
}

variable "vpc_cidr" {
  type = string
}

variable "certificate" {
  type = string
}
