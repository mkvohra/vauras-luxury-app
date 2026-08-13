#LOOK UP THE GITHUB OIDC PROVIDER DIRECTLY
#(same lookup bootstrap does - it's account-wide and already exists,
#so we don't need to depend on bootstrap's local state to get its ARN)

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"  
}

#========================================================================================================

#CALLING IAM MODULE

module "iam" {

  source = "../../../modules/iam"

  project_name = var.project_name

  environment = var.environment

  aws_region = var.aws_region

  github_org = var.github_org

  github_repo = var.github_repo 

  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn

  terraform_state_bucket = var.terraform_state_bucket

  terraform_lock_table = var.terraform_lock_table

  cluster_name = "${var.project_name}-${var.environment}"

  bucket_name = var.bucket_name

  ecr_repositories = var.repositories  
}