# ============================================================
# FIND THE PUBLIC ROUTE53 HOSTED ZONE
# ============================================================

data "aws_route53_zone" "this" {

  name = var.domain_name

  private_zone = false
}

#------------------------------------------------------------------------------------

# S3 MODULE 

module "s3" {

  source = "../../../modules/s3"

  bucket_name = var.bucket_name
  environment = var.environment
  enable_versioning = var.enable_versioning  
} 

#-------------------------------------------------------------------------------


#  CLOUDFRONT ACM CERTIFICATE

module "cloudfront_acm" {

  source = "../../../modules/acm"

  providers = {
    aws = aws.virginia
  }

  project_name = var.project_name
  environment = var.environment
  domain_name = "${var.frontend_subdomain}.${var.domain_name}"
  subject_alternative_names = [ ]

  hosted_zone_id = data.aws_route53_zone.this.zone_id

}

#----------------------------------------------------

#  ALB ACM CERTIFICATE

module "alb_acm" {

  source = "../../../modules/acm"

  # IMPORTANT:
  # No provider override here.
  # Therefore this uses the normal AWS provider,
  # which is ap-south-1.

  project_name = var.project_name
  environment  = var.environment

  domain_name = "${var.api_subdomain}.${var.domain_name}"

  subject_alternative_names = []

  hosted_zone_id = data.aws_route53_zone.this.zone_id
}



#--------------------------------------------------------------------------------------------------


#CLOUDFRONT MODULE

module "cloudfront" {
  source = "../../../modules/cloudfront"

  project_name = var.project_name
  environment = var.environment
  domain_name = var.domain_name
  certificate_arn = module.cloudfront_acm.certificate_arn
  s3_bucket_id = module.s3.bucket_id
  s3_bucket_arn = module.s3.bucket_arn
  s3_bucket_regional_domain_name = module.s3.regional_domain_name

}
