output "github_oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.github.arn  
}
output "hosted_zone_id" {
  value = aws_route53_zone.this.zone_id  
}

output "hosted_zone_name_servers" {
  value = aws_route53_zone.this.name_servers  
}

output "domain_name" {
  value = aws_route53_zone.this.name  
}

output "terraform_state_bucket" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "terraform_lock_table" {
  value = aws_dynamodb_table.terraform_locks.name
}