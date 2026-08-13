# S3 BACKEND BUCKET

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform_state_bucket

  tags = {
    Project = var.project_name
  }      
} 

# -----------------------------------

# S3 BUCKET VERSIONING

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id


  versioning_configuration {
    status = "Enabled"
  }

}

#----------------------------------

# S3 BUCKET ENCRYPTION

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  
    }
  }  
}

#-------------------------------------
# S3 BUCKET PUBLIC ACCESS BLOCKED

resource "aws_s3_bucket_public_access_block" "terraform_state_public_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls = true
  ignore_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}


#-------------------------------------------------------------------------------------------------

# DYNAMODB LOCK TABLE

resource "aws_dynamodb_table" "terraform_locks" {
  name = var.terraform_lock_table
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags ={
    Project = var.project_name
  }
}

#------------------------------------------------------------------------------------------





# GITHUB OIDC PROVIDER already existing thus reading from the aws 

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}




#----------------------------------------------------------------------------------------------------

#ADDING HOSTED ZONE TO GLOBAL LEVEL (as it should not exist per environment)

resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = {
    Name = var.domain_name
  }  
}