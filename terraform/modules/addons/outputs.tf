output "aws_lb_controller_role_arn" {
  value = aws_iam_role.aws_lb_controller.arn  
}

output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn  
}

output "aws_lb_controller_role_name" {
  value = aws_iam_role.aws_lb_controller.name
}

output "cluster_autoscaler_role_name" {
  value = aws_iam_role.cluster_autoscaler.name
}

output "external_dns_role_arn" {
  value = aws_iam_role.external_dns.arn
}

output "external_dns_role_name" {
  value = aws_iam_role.external_dns.name
} 

output "external_secrets_role_arn" {
  value = aws_iam_role.external_secrets.arn
} 