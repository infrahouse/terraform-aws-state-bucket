resource "random_pet" "bucket" {
  prefix = "pytest-state-bucket"
}
module "state-bucket" {
  source = "./../../"
  bucket = random_pet.bucket.id

  replication_region = var.replication_region
}
