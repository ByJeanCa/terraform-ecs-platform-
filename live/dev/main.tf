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
}

module "jean_vpc_module" {
  source = "../../modules/network"
  providers = {
    aws = aws
  }


  region      = var.region
  environment = var.environment
  az_count    = 2
  vpc_cidr    = "10.0.0.0/16"
  newbits     = 8
  common_tags = var.common_tags
}

module "jean_acm_module" {
  source = "../../modules/acm"
  providers = {
    aws = aws
  }


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
  source = "../../modules/dns"

  providers = {
    aws = aws
  }


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
  source = "../../modules/alb"

  providers = {
    aws = aws
  }


  common_tags = var.common_tags
  environment = var.environment
  region      = var.region
  vpc_id      = module.jean_vpc_module.vpc_id
  subnets     = module.jean_vpc_module.public_subnets
  vpc_cidr    = "10.0.0.0/16"
  certificate = data.aws_acm_certificate.issued.arn
}


module "jean_ecr_module" {
  source = "../../modules/ecr"

  providers = {
    aws = aws
  }


  common_tags = var.common_tags
  environment = var.environment
  region      = var.region
  app_name    = var.app_name
}

module "jean_ecs_module" {
  source = "../../modules/ecs"

  providers = {
    aws = aws
  }


  app_name             = var.app_name
  environment          = var.environment
  region               = var.region
  common_tags          = var.common_tags
  target_group_arn     = module.jean_alb_module.target_group_arn
  private_subnets      = module.jean_vpc_module.private_subnets
  vpc_id               = module.jean_vpc_module.vpc_id
  ecr_repository_url   = module.jean_ecr_module.repository_url
  alb_sg_id            = module.jean_alb_module.alb_sg_id
  db_master_secret_arn = module.jean_db_module.db_master_secret_arn
  db_host = module.jean_db_module.db_host
  db_name = module.jean_db_module.db_name
  
}


module "jean_db_module" {
  source = "../../modules/db"

  providers = {
    aws = aws
  }


  environment     = var.environment
  region          = var.region
  vpc_id          = module.jean_vpc_module.vpc_id
  ecs_sg_id       = module.jean_ecs_module.ecs_sg_id
  common_tags     = var.common_tags
  private_subnets = module.jean_vpc_module.private_subnets
  db_subnet_name  = module.jean_vpc_module.database_subnet_group
}

module "jean_observability_module" {
  source = "../../modules/observability"

  providers = {
    aws = aws
  }
  environment = var.environment
  app_name = var.app_name
  email = var.email
  cluster_name = module.jean_ecs_module.ecs_cluster_name
  service_name = module.jean_ecs_module.ecs_service_name
}

module "jean_budged_module" {
  source = "../../modules/cost_guardrails"
  providers = {
    aws = aws
  }

  email = var.email
  ecs_id = module.jean_ecs_module.ecs_autoscaling_resource_id
}

