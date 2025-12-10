output "ecs_sg_id" {
  value = aws_security_group.svc.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.app_clust.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app_service.name
}