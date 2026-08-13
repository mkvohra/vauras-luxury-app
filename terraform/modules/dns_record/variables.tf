variable "hosted_zone_id" {
  type = string  
}

variable "domain_name" {
  type = string  
}

variable "cloudfront_domain_name" {
  type = string  
}

variable "cloudfront_hosted_zone_id" {
  type = string  
}

#variable "alb_dns_name" {
#  type = string
#  default = null  
#}

#variable "alb_zone_id" {
#  type = string
#  default = null  
#}

variable "frontend_subdomain" {
  type = string
}

variable "api_subdomain" {
  type = string
}