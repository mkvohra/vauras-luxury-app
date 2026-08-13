# USING VPC REMOTE STATE FILE USING (terraform_remote_state)

data "terraform_remote_state" "vpc" {

  backend = "s3"

  config = {

    bucket = "vauras-terraform-state"

    key = "dev/vpc/terraform.tfstate"

    region = "ap-south-1"
  }  
}

#-----------------------------------------------------------------------------------------

#CALLING EKS MODULE

module "eks" {

  source = "../../../modules/eks"

  project_name = var.project_name

  environment = var.environment

  cluster_name = "${var.project_name}-${var.environment}"

  cluster_version = var.cluster_version

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  public_subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  node_instance_types = var.node_instance_types

  desired_size = var.desired_size

  min_size = var.min_size
  
  max_size = var.max_size

}