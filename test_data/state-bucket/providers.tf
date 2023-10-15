provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::303467602807:role/state-bucket-tester"
  }
  region = "us-west-1"
  default_tags {
    tags = {
      "created_by" : "infrahouse/terraform-aws-state-bucket" # GitHub repository that created a resource
    }

  }
}
