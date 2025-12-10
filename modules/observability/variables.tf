variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
}

variable "app_name" {
  type = string
}

variable "email" {
  type = string
  description = "Email to send to notify about CloudWatch Alarms"
}

variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}