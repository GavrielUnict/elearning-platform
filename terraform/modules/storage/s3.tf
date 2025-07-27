# Bucket per i documenti
resource "aws_s3_bucket" "documents" {
  bucket = "${var.project_name}-${var.environment}-documents-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-documents"
  }
}

# Versioning per documents bucket
resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption per documents bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle rule per archiviazione dopo 90 giorni
resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id
  
  rule {
    id     = "archive-old-documents"
    status = "Enabled"
    
    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }
    
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER_IR"
    }
  }
}

# CORS configuration per upload diretto
resource "aws_s3_bucket_cors_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id
  
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Block public access per documents bucket
resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket per static assets
resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.project_name}-${var.environment}-static-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-static-assets"
  }
}

# Server-side encryption per static assets bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Static website hosting
resource "aws_s3_bucket_website_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "error.html"
  }
}

# CORS configuration per static assets
resource "aws_s3_bucket_cors_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Block public access per static assets (sarà configurato con CloudFront nella Fase 5)
resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Random suffix per bucket names
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}