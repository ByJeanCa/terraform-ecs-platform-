output "ecr_repository_url" {
  description = "ECR repository URL for CI/CD"
  value       = module.jean_ecr_module.repository_url
}

output "ecs_cluster_name" {
  value = module.jean_ecs_module.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.jean_ecs_module.ecs_service_name
}