terraform {

  backend "s3" {

    bucket = "vauras-terraform-state"
    key = "dev/rds/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "vauras-terraform-locks"

    encrypt = true
  }  
}