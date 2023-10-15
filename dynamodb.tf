resource "random_pet" "suffix" {
  prefix = var.bucket
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = random_pet.suffix.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  tags = merge(var.tags, {
    "state_bucket" : var.bucket
  })


  attribute {
    name = "LockID"
    type = "S"
  }
}
