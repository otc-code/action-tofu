#---------------------------------------------------------------------------------------------------
# Bucket
#---------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV2_AWS_62: Event notification not necessary for state files in autopilot
  #checkov:skip=CKV_AWS_144: Cross region not necessary for state files in autopilot
  #checkov:skip=CKV_AWS_145: KMS encrption not necessary for state files in autopilot
  #checkov:skip=CKV_AWS_18: Acces logging not necessary for state files in autopilot
  #checkov:skip=CKV2_AWS_61: No lifecycle for state files in autopilot

  bucket        = var.s3_bucket_name
  force_destroy = true
  tags = {
    Name       = "${var.s3_bucket_name}-s3"
    Managed_by = "CI/CD: ${var.workflow}"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#---------------------------------------------------------------------------------------------------
# DynamoDB Table for State Locking
#---------------------------------------------------------------------------------------------------

locals {
  # The table must have a primary key named LockID.
  # See below for more detail.
  # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table
  lock_key_id = "LockID"
}

resource "aws_dynamodb_table" "lock" {
  #checkov:skip=CKV_AWS_119: DynabamoDB table only contains locks, so no encryption necessary
  name         = var.dynamodb_table_name
  hash_key     = local.lock_key_id
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = local.lock_key_id
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
  tags = {
    Name       = "${var.dynamodb_table_name}-dynamodb"
    Managed_by = "CI/CD: ${var.workflow}"
  }
}
