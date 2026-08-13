output "frontend_record_fqdn" {
  value = aws_route53_record.frontend.fqdn  
}

output "api_record_fqdn" {

  value = (
    length(aws_route53_record.api) > 0
      ? aws_route53_record.api[0].fqdn
      : null
  )
}

# GitHub Actions wants those values.
output "api_hostname" {
  value = local.api_hostname
}

output "frontend_hostname" {
  value = local.frontend_hostname
}