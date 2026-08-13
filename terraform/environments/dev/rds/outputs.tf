output "db_endpoint" {
  value = module.rds.db_endpoint  
}

output "db_port" {
  value = module.rds.db_port  
}

output "db_identifier" {
  value = module.rds.db_identifier  
}

output "db_name" {
  value = module.rds.db_name  
}

output "security_group_id" {
  value = module.rds.security_group_id  
}

output "db_password" {
  value = module.rds.db_password
  sensitive = true
}

output "db_username" {
  value = module.rds.db_username
}