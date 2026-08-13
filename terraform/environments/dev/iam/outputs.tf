output "terraform_role_arn" {
  value = module.iam.terraform_role_arn
}

output "deployment_role_arn" {
  value = module.iam.deployment_role_arn
}

output "frontend_role_arn" {
  value = module.iam.frontend_role_arn
}
