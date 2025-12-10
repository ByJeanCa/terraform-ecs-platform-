terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }

  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name                       = format("%s-%s-alb", var.environment, var.region)
  vpc_id                     = var.vpc_id
  subnets                    = var.subnets
  enable_deletion_protection = false


  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr
    }
  }

  listeners = {
    http_redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https_forward = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate

      forward = {
        target_group_key = "default"
      }
    }
  }

  target_groups = {
    default = {
      name_prefix = "def"
      protocol    = "HTTP"
      port        = 8080
      target_type = "ip"
      health_check = {
        path                = "/health"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 10
        matcher             = "200-399"
      }
      deregistration_delay = 15
      create_attachment    = false
    }
  }
}

