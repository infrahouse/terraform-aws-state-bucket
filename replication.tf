resource "aws_s3_bucket" "replica" {
  bucket = "${var.bucket}-replica"
  region = var.replication_region

  tags = merge(
    local.tags,
    var.tags,
    {
      "vanta-exempt:aws-s3-cross-region-replication-enabled" = join("", [
        "Replica destination bucket - ",
        "CRR test applies to source not target",
      ])
    },
  )

  lifecycle {
    precondition {
      condition     = length(var.bucket) <= 55
      error_message = <<-EOT
        bucket must be <= 55 characters when replication is enabled
        (63 max minus 8 for '-replica' suffix). Got: ${length(var.bucket)}
      EOT
    }
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  bucket = aws_s3_bucket.replica.id
  region = var.replication_region
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  bucket = aws_s3_bucket.replica.id
  region = var.replication_region

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  bucket                  = aws_s3_bucket.replica.id
  region                  = var.replication_region
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "replica_ssl_policy" {
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.replica.arn,
      "${aws_s3_bucket.replica.arn}/*",
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

resource "aws_s3_bucket_policy" "replica" {
  bucket = aws_s3_bucket.replica.id
  region = var.replication_region
  policy = data.aws_iam_policy_document.replica_ssl_policy.json
}

data "aws_iam_policy_document" "replication_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "replication_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.state-bucket.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = [
      "${aws_s3_bucket.state-bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = [
      "${aws_s3_bucket.replica.arn}/*",
    ]
  }
}

resource "aws_iam_role" "replication" {
  name_prefix        = "s3-replication-"
  assume_role_policy = data.aws_iam_policy_document.replication_assume_role.json
}

resource "aws_iam_role_policy" "replication" {
  name   = "s3-replication"
  role   = aws_iam_role.replication.id
  policy = data.aws_iam_policy_document.replication_policy.json
}

resource "aws_s3_bucket_replication_configuration" "state_bucket" {
  bucket = aws_s3_bucket.state-bucket.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD_IA"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.enabled,
    aws_s3_bucket_versioning.replica,
  ]
}
