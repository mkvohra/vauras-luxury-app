output "terraform_role_arn" {
  value = aws_iam_role.terraform.arn
}

output "deployment_role_arn" {
  value = aws_iam_role.deployment.arn
}

output "frontend_role_arn" {
  value = aws_iam_role.frontend.arn
}

output "terraform_plan_role_arn" {
  description = "ARN of the Terraform plan-only IAM role"
  value       = aws_iam_role.terraform_plan.arn
}