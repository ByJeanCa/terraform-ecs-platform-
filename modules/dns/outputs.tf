output "name_servers" {
  value = data.aws_route53_zone.main.name_servers
}

output "zone_name" {
  value = data.aws_route53_zone.main.name
}

output "validation_record_fqdns" {
  value = [for r in aws_route53_record.acm_validation : r.fqdn]
}
output "zone_id" { value = data.aws_route53_zone.main.zone_id }