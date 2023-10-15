# Bucket configuration credit:
# https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa

resource "aws_s3_bucket" "state-bucket" {
  bucket = var.bucket
  lifecycle {
    prevent_destroy = false
  }
  tags = var.tags
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.state-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.state-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.state-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
