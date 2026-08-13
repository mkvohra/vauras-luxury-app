#ASKING AWS FOR HOSTED ZONE ID DIRECTLY (instead of asking terraform for outputs , cuz if we would ask terraform for outputs then we have to move bootstrap state to remote s3 bucket .)

data "aws_route53_zone" "this" {

  name = var.domain_name

  private_zone = false

}



data "terraform_remote_state" "frontend" {

  backend = "s3"

  config = {
    bucket = "vauras-terraform-state"
    key = "dev/frontend/terraform.tfstate"
    region = "ap-south-1"
  }  
}


module "dns_records" {

  source = "../../../modules/dns_record" 

  hosted_zone_id = data.aws_route53_zone.this.zone_id

  domain_name = var.domain_name
  cloudfront_domain_name = data.terraform_remote_state.frontend.outputs.cloudfront_distribution_domain_name
  cloudfront_hosted_zone_id = data.terraform_remote_state.frontend.outputs.cloudfront_distribution_hosted_zone_id

  #alb_dns_name = null
  #alb_zone_id = null 

  frontend_subdomain = var.frontend_subdomain
  api_subdomain = var.api_subdomain
}