terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">=5.0.0"
    }
  }
}

provider "aws" {
  region = var.region
  profile = "jeanca"
}

resource "aws_route53_zone" "primary" {
  name = var.domain

  tags = var.common_tags
}
