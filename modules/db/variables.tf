variable "region" {
  type        = string
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/stage/prod)"
}

variable "vpc_id" {
  type = string
}

variable "ecs_sg_id" {
  type = string
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Base tags to merge into all resources"
}

variable "private_subnets" {
  type = list(string)
}

variable "db_subnet_name" {
  type = string
}

