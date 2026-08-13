terraform {

  required_version = ">= 1.5"

  required_providers {

    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"  
    }

    random = {
      source = "hashicorp/random"
      version = "~> 3.7"  
    }
  }  
}


# NORMAL REGION
# ALB certificate lives here


provider "aws" {
  region = var.aws_region
}


# CLOUDFRONT REGION
# CloudFront certificate must live in us-east-1

provider "aws" {
  alias = "virginia"
  region = "us-east-1"
  


}