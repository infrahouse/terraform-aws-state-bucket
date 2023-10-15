output "bucket_name" {
  value       = aws_s3_bucket.state-bucket.bucket
  description = "Name of the created S3 bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.state-bucket.arn
  description = "ARN of the created S3 bucket."
}
