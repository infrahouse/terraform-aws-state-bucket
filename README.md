# Module terraform-aws-state-bucket

Amazon S3 backend is a popular storage for a Terraform state.

[Hashicorp](https://developer.hashicorp.com/terraform/language/settings/backends/s3) itself 
and [Gruntwork](https://blog.gruntwork.io/how-to-manage-terraform-state-28f5697e68fa)
developed recommendations for the S3 bucket configuration, 
so storing the Terraform state is safe.

The module creates an S3 bucket, a DynamoDB table for a state lock, 
and implements these recommendations.

The DynamoDB table name is generated with the state bucket name 
prefix.

The S3 bucket and DynamoDB table names and ARNs are exported as module 
outputs.

## Usage

```hcl
module "state-bucket" {
  source  = "infrahouse/state-bucket/aws"
  version = "~> 2.0"
  bucket  = "bucket-name"
}
```
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.11 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.11 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.terraform_locks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_s3_bucket.state-bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.public_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.enabled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [random_pet.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket"></a> [bucket](#input\_bucket) | Bucket name for a Terraform state | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply on S3 bucket | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the created S3 bucket. |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the created S3 bucket. |
| <a name="output_lock_table_arn"></a> [lock\_table\_arn](#output\_lock\_table\_arn) | ARN of the created DynamoDB table for state locks. |
| <a name="output_lock_table_name"></a> [lock\_table\_name](#output\_lock\_table\_name) | Name of the created DynamoDB table for state locks. |
