#ADDING REMOTE STATES
#(VPC REMOTE STATE)

data "terraform_remote_state" "vpc" {

  backend = "s3"

  config = {

    bucket = "vauras-terraform-state"
    key  = "dev/vpc/terraform.tfstate"
    region = "ap-south-1"

  }  
}

#(EKS REMOTE STATE)

data "terraform_remote_state" "eks" {

  backend = "s3"

  config = {

    bucket = "vauras-terraform-state"
    key = "dev/eks/terraform.tfstate"
    region = "ap-south-1"

  }  
}
#---------------------------------------------------------------------------------------------------

#CALLING RDS MODULE

module "rds" {

  source = "../../../modules/rds"

  project_name = var.project_name

  environment = var.environment

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  cluster_security_group_id = data.terraform_remote_state.eks.outputs.cluster_security_group_id

  db_name = var.db_name

  db_username = var.db_username

  db_instance_class = var.db_instance_class

  allocated_storage = var.allocated_storage

  engine_version = var.engine_version

  multi_az = var.multi_az

  deletion_protection = var.deletion_protection

  skip_final_snapshot = var.skip_final_snapshot  
}