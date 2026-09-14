output "terraform_role_arn" {
  value = module.iam.terraform_role_arn
}

output "deployment_role_arn" {
  value = module.iam.deployment_role_arn
}

output "frontend_role_arn" {
  value = module.iam.frontend_role_arn
}

output "terraform_plan_role_arn" {
  description = "ARN of the Terraform plan-only IAM role"
  value       = module.iam.terraform_plan_role_arn
}