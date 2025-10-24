variable "app_name" {
  type = string
  description = "Name of the application"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
}

variable "region" {
  type        = string
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Base tags to merge into all resources"
}