variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
}

variable "region" {
  type = string
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Base tags to merge into all resources"
}

variable "target_group_arn" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "db_master_secret_arn" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}
