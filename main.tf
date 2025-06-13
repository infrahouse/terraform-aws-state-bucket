# Bucket configuration credit:
# https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa

resource "aws_s3_bucket" "state-bucket" {
  bucket = var.bucket
  lifecycle {
    prevent_destroy = false
  }
  tags = merge(
    local.tags,
    var.tags,
    {
      "lock_table" : aws_dynamodb_table.terraform_locks.name
      "module_version" : local.module_version
    }
  )
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

resource "aws_s3_bucket_policy" "state-bucke" {
  bucket = aws_s3_bucket.state-bucket.id
  policy = data.aws_iam_policy_document.enforce_ssl_policy.json
}

data "aws_iam_policy_document" "enforce_ssl_policy" {
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.state-bucket.arn,
      "${aws_s3_bucket.state-bucket.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

}
