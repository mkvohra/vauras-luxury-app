resource "random_string" "bucket_suffix" {

  length = 6
  upper = false
  special = false  
}

# S3 bucket_name
resource "aws_s3_bucket" "frontend" {

  bucket = "${var.bucket_name}-${var.environment}-frontend-${random_string.bucket_suffix.result}"

  tags = {
    Project = var.bucket_name
    Environment = var.environment
  }  
}

#BLOCK PUBLIC ACCESS 

resource "aws_s3_bucket_public_access_block" "frontend" {

  bucket = aws_s3_bucket.frontend.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


#BUCKET VERSIONING 

resource "aws_s3_bucket_versioning" "frontend" {

  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }

}

# BUCKET ENCRYPTION 

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {

  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {

      sse_algorithm = "AES256"  
    }
  }  
}

# BUCKET OWNERSHIP CONTROLS

resource "aws_s3_bucket_ownership_controls" "frontend" {

  bucket = aws_s3_bucket.frontend.id

  rule {

    object_ownership = "BucketOwnerEnforced"
  }  
}