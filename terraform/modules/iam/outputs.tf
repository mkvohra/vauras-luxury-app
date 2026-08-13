output "terraform_role_arn" {
  value = aws_iam_role.terraform.arn
}

output "deployment_role_arn" {
  value = aws_iam_role.deployment.arn
}

output "frontend_role_arn" {
  value = aws_iam_role.frontend.arn
}
