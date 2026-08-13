#ADDING REMOTE STATE
#(RDS REMOTE STATE- gives us the endpoint, port, name, username, and generated password)

data "terraform_remote_state" "rds" {

  backend = "s3"

  config = {

    bucket = "vauras-terraform-state"
    key = "dev/rds/terraform.tfstate"
    region = "ap-south-1"

  }  
}

#-------------------------------------------------------------------------------------------------------------------------------

#CALLING SECRET-MANAGER MODULE

module "secrets_manager" {

  source = "../../../modules/secrets-manager"

  project_name = var.project_name

  environment = var.environment

  db_host = data.terraform_remote_state.rds.outputs.db_endpoint

  db_port = tostring(data.terraform_remote_state.rds.outputs.db_port)

  db_name = data.terraform_remote_state.rds.outputs.db_name

  db_username = data.terraform_remote_state.rds.outputs.db_username

  db_password = data.terraform_remote_state.rds.outputs.db_password
}