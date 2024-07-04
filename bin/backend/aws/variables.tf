variable "cloud_region" {
  type        = string
  description = "define the location which tf should use."
}

variable "s3_bucket_name" {
  description = "S3 bucket name which stores the terraform state"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name which stores the terraform lock"
  type        = string
}

variable "workflow" {
  # Default to absent/blank to use the default aws/s3 aws kms master key
  default     = "n/a"
  description = "The AWS KMS master key ID used for the SSE-KMS encryption on the tf state s3 bucket. If the kms_key_id is specified, the bucket default encryption key management method will be set to aws-kms. If the kms_key_id is not specified (the default), then the default encryption key management method will be set to aes-256 (also known as aws-s3 key management). The default aws/s3 AWS KMS master key is used if this element is absent (the default)."
}
