output "db_endpoint" {
  value = aws_db_instance.this.endpoint  
}

output "db_port" {
  value = aws_db_instance.this.port  
}

output "db_identifier" {
  value = aws_db_instance.this.identifier  
}

output "db_name" {
  value = aws_db_instance.this.db_name  
}

output "security_group_id" {
  value = aws_security_group.rds.id  
}

output "db_password" {
  value = random_password.db_password.result
  sensitive = true
}

output "db_username" {
  value = aws_db_instance.this.username
}