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

resource "aws_route53_record" "lb_a_record" {
    zone_id = aws_route53_zone.main.id
    name = var.domain
    type = "A"
   
   alias {
    name = var.lb_name
    zone_id = var.lb_zone_id
    evaluate_target_health = true
   }
}