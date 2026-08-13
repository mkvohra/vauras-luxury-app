# ORIGIN ACCESS CONTROL

resource "aws_cloudfront_origin_access_control" "this" {

  name = "${var.project_name}-${var.environment}-oac"
  description = "Cloudfront Access to Private s3"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"  
}


# CLOUDFRONT DISTRIBUTION

resource "aws_cloudfront_distribution" "this" {

  enabled = true
  
  #CloudFront accepts or handles requests from this domain name
  aliases = [
    var.domain_name
  ]  

  default_root_object = "index.html"
  
  # (actual content stored here in this origin and Define available backends)

  origin {

    domain_name = var.s3_bucket_regional_domain_name
    origin_id = var.s3_bucket_id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id 
  }

  default_cache_behavior {

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"  
    ]

    cached_methods = [
      "GET",
      "HEAD"  
    ]

    target_origin_id = var.s3_bucket_id
    viewer_protocol_policy = "redirect_to_https"
    compress = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {

    geo_restriction {
      restriction_type = "none"  
    }
  }

  viewer_certificate {

    acm_certificate_arn = var.certificate_arn

    ssl_support_method = "sni-only"

    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Project = var.project_name
    Environment = var.environment
  }
}

#S3 BUCKET POLICY (trust relationship)

data "aws_iam_policy_document" "cloudfront_access" {

  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${var.s3_bucket_arn}/*"
    ] 

    principals {

      type = "Service"

      identifiers = [
        "cloudfront.amazonaws.com"
      ]
    }

    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        aws_cloudfront_distribution.this.arn
      ]
    }
  }
}

#S3 BUCKET POLICY CREATION

resource "aws_s3_bucket_policy" "this" {

  bucket = var.s3_bucket_id

  policy = data.aws_iam_policy_document.cloudfront_access.json
}
 