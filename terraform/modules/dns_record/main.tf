locals {

  frontend_hostname =
    var.frontend_subdomain == ""
    ? var.domain_name
    : "${var.frontend_subdomain}.${var.domain_name}"

  api_hostname =
    var.api_subdomain == ""
    ? var.domain_name
    : "${var.api_subdomain}.${var.domain_name}"
}



# FRONTEND MAPPING

resource "aws_route53_record" "frontend" {

  zone_id = var.hosted_zone_id

  name = local.frontend_hostname

  type = "A"

  alias {

    name = var.cloudfront_domain_name

    zone_id = var.cloudfront_hosted_zone_id

    evaluate_target_health = false
  }   
}

#===================================================================================================================================================

# ALB MAPPING (COMMENTED OUT OR REMOVED FROM TERRAFORM BECAUSE WE HAVE DELEGATED THIS RESONSIBILITY TO THE 
#ExternalDNS controller that watched the ingress and then aqutomatically handles the alb mapping)

#resource "aws_route53_record" "api" {
#
#  count =
#    var.alb_dns_name != null &&
#    var.alb_zone_id != null ? 1 : 0
#
#  zone_id = var.hosted_zone_id
#
#  name = local.api_hostname
#
#  type = "A"
#
#  alias {
#
#    name = var.alb_dns_name
#
#    zone_id = var.alb_zone_id
#
#    evaluate_target_health = true
#  }
#}