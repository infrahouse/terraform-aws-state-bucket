resource "random_pet" "suffix" {
  prefix = var.bucket
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = random_pet.suffix.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  tags = merge(
    local.tags,
    var.tags,
    {
      "state_bucket" : var.bucket
      VantaNoAlert : "Table used for Terraform state lock and does not contain user data"
    }
  )

  attribute {
    name = "LockID"
    type = "S"
  }
}
