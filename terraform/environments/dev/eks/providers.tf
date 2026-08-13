terraform {

  required_version = ">= 1.5"

  required_providers {

    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"  
    }

    tls = {
      source = "hashicorp/tls"  
    }
  }  
}

provider "aws" {
  region = var.aws_region  
}