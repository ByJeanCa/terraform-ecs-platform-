terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

resource "aws_ecr_repository" "ecr_repo" {
  name   = format("%s-%s-%s-ecr", var.app_name, var.environment, var.region)
  region = var.region

  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.common_tags
}

