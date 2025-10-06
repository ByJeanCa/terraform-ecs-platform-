output "Name servers" {
  value = aws_route53_zone.main.name_servers
}
output "zone_id" {
  value = aws_route53_zone.main.id
}

output "zone_name" {
  value = aws_route53_zone.main.name
}
