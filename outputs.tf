output "bucket_name" {
  value       = aws_s3_bucket.state-bucket.bucket
  description = "Name of the created S3 bucket."
}

output "bucket_arn" {
  value       = aws_s3_bucket.state-bucket.arn
  description = "ARN of the created S3 bucket."
}

output "lock_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "Name of the created DynamoDB table for state locks."
}

output "lock_table_arn" {
  value       = aws_dynamodb_table.terraform_locks.arn
  description = "ARN of the created DynamoDB table for state locks."
}
