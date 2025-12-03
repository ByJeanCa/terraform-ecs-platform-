output "alb_arn" {
  value = module.alb.arn
}
output "alb_dns_name" {
  value = module.alb.dns_name
}
output "alb_zone_id" {
  value = module.alb.zone_id
}
output "alb_sg_id" {
  value = module.alb.security_group_id
}

output "target_group_arn" {
  value = module.alb.target_groups["default"].arn
}

output "sg" {
  value = module.alb.security_group_id
}