terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "jeanca"
}

module "jean_vpc_module" {
  source = "./modules/network"

  region      = var.region
  environment = var.environment
  az_count    = 2
  vpc_cidr    = "10.0.0.0/16"
  newbits     = 8
  common_tags = var.common_tags
}

module "jean_acm_module" {
  source      = "./modules/acm"
  domain      = var.domain
  common_tags = var.common_tags

}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = module.jean_acm_module.certificate_arn
  validation_record_fqdns = module.jean_dns_module.validation_record_fqdns
}

data "aws_acm_certificate" "issued" {
  domain      = var.domain
  types       = ["AMAZON_ISSUED"]
  statuses    = ["ISSUED"]
  most_recent = true
  depends_on  = [aws_acm_certificate_validation.cert]
}

module "jean_dns_module" {
  source = "./modules/dns"

  domain       = var.domain
  common_tags  = var.common_tags
  alb_dns_name = module.jean_alb_module.alb_dns_name
  alb_zone_id  = module.jean_alb_module.alb_zone_id
  dvo          = module.jean_acm_module.domain_validation_options
}

locals {
  public_subnets_id = module.jean_vpc_module.public_subnets
}

module "jean_alb_module" {
  source = "./modules/alb"

  common_tags = var.common_tags
  environment = var.environment
  region      = var.region
  vpc_id      = module.jean_vpc_module.vpc_id
  subnets     = module.jean_vpc_module.public_subnets
  vpc_cidr    = "10.0.0.0/16"
  certificate = data.aws_acm_certificate.issued.arn
}

