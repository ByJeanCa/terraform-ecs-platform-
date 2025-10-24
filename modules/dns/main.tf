terraform {
  required_providers{
    aws = {
        source = "hashicorp/aws"
        version = ">= 5.0.0"
    }
  }
}

resource "aws_route53_zone" "main" {
  name = var.domain
  tags = var.common_tags
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for o in var.dvo : o.domain_name => {
      name  = o.resource_record_name
      type  = o.resource_record_type
      value = o.resource_record_value
    }
  }
    zone_id = aws_route53_zone.main.id
    name = each.value.name
    type = each.value.type
    ttl = 60
    records = [each.value.value]
}

resource "aws_route53_record" "lb_a_record" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}