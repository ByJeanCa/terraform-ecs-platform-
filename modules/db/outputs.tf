output "db_master_secret_arn" {
  value = module.db.db_instance_master_user_secret_arn
}

output "db_host" {
  value = module.db.db_instance_endpoint
}

output "db_name" {
  value = module.db.db_instance_name
}


