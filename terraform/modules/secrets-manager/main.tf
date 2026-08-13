#GENERATE THE JWT SIGNING SECRET
#(shared between auth-service and cart-service - auth signs token, cart verifies them)

resource "random_password" "jwt_secret" {

  length =  40
  special = false  
}

#----------------------------------------------------------------------------------------------------------

#SECRET MANAGER SECRET (container for the app's runtime secrets)

resource "aws_secretsmanager_secret" "this" {
  
  name = "${var.project_name}/${var.environment}/app-secrets"

  description = "Runtime secrets for ${var.project_name} (${var.environment})"

  tags = {
    Project = var.project_name
    Environment = var.environment
  }
}

#-----------------------------------------------------------------------------------------------------------------

#SECRET VERSION (the actual JSON content, in one place used by both services)

resource "aws_secretsmanager_secret_version" "this" {

  secret_id = aws_secretsmanager_secret.this.id

  secret_string = jsoncode({
    DB_HOST = var.db_host
    DB_PORT = var.db_port
    DB_NAME = var.db_name 
    DB_USER = var.db_username
    DB_PASSWORD = var.db_password
    JWT_SECRET = random_password.jwt_secret.result
  })  
}