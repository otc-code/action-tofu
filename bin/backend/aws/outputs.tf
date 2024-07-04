output "s3_bucket_id" {
  description = "The name of the bucket."
  value       = resource.aws_s3_bucket.state.id
}

output "s3_bucket_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = resource.aws_s3_bucket.state.arn
}

output "s3_bucket_region" {
  description = "The AWS region this bucket resides in."
  value       = var.cloud_region
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = resource.aws_dynamodb_table.lock.arn
}

output "dynamodb_table_id" {
  description = "ID of the DynamoDB table"
  value       = resource.aws_dynamodb_table.lock.id
}