variable "bucket" {
  description = "Bucket name for a Terraform state"
  type        = string

  validation {
    condition     = length(var.bucket) <= 63
    error_message = "bucket must be <= 63 characters. Got: ${length(var.bucket)}"
  }
}

variable "replication_region" {
  description = "AWS region for the replica bucket."
  type        = string
}

variable "tags" {
  description = "Tags to apply on S3 bucket"
  type        = map(string)
  default     = {}
}
