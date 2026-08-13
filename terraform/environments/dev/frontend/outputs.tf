output "bucket_id" {
  value = module.s3.bucket_id  
}
 
output "bucket_arn" {
  value = module.s3.bucket_arn   
}

output "bucket_name" {
  value = module.s3.bucket_name  
}

output "regional_domain_name" {
  value = module.s3.regional_domain_name  
}

output "bucket_domain_name" {
  value = module.s3.bucket_domain_name
}

#output "certificate_arn" {
#  value = module.acm.certificate_arn------------------------------>do not forget to remove it after inspection
#}                      --------------> make sure to see if we have use this outut anywhere or not.

output "cloudfront_distribution_id" {
  value = module.cloudfront.distribution_id
}

output "cloudfront_distribution_domain_name" {
  value = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  value = module.cloudfront.distribution_hosted_zone_id
}

output "cloudfront_certificate_arn" {
  value = module.cloudfront_acm.certificate_arn
}

output "alb_certificate_arn" {
  value = module.alb_acm.certificate_arn
}