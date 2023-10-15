variable "bucket" {
  description = "Bucket name for a Terraform state"
  type        = string
}

variable "tags" {
  description = "Tags to apply on S3 bucket"
  type        = map(string)
  default     = {}
}
