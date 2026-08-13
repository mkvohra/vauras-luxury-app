# CREATE ACM CERTIFICATE

resource "aws_acm_certificate" "this" {

  domain_name = var.domain_name

  subject_alternative_names = var.subject_alternative_names

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }  

  tags = {
    Project = var.project_name
    Environment = var.environment
  }
}


# CREATE DNS VALIDATION RECORDS
# (given as challenge by acm certificate authority , 
#which is to be stored inside the hosted zone where other mappings exists)

resource "aws_route53_record" "validation" {

  for_each = {

    for dvo in aws_acm_certificate.this.domain_validation_options :

    dvo.domain_name => {
      name = dvo.resource_record_name

      record = dvo.resource_record_value

      type = dvo.resource_record_type
    }
  }
  zone_id = var.hosted_zone_id
  name = each.value.name
  type = each.value.type
  ttl = 60
  records = [
    each.value.record
  ]
}

#ACM CERTIFICATE VALIDATION (Wait until ACM finishes validation.)

# (it tells Terraform: Do not move forward until ACM says the certificate is ISSUED.)
#(With it: Terraform knows: Certificate requested-> Certificate validated-> Certificate issued.)

resource "aws_acm_certificate_validation" "this" {
  
  certificate_arn = aws_acm_certificate.this.arn 

  validation_record_fqdns = [
    for record in aws_route53_record.validation :
    record.fqdn
  ]
}

