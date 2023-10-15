output "bucket_name" {
  value = module.state-bucket.bucket_name
}

output "bucket_arn" {
  value = module.state-bucket.bucket_arn
}

output "lock_table_name" {
  value = module.state-bucket.lock_table_name
}

output "lock_table_arn" {
  value = module.state-bucket.lock_table_arn
}
