terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0.0" }
  }
}

provider "aws" {
  region  = var.region
  profile = "jeanca"
}

data "aws_caller_identity" "current" {}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"
  bucket = format("ecs-tfstate-%s-%s", data.aws_caller_identity.current.account_id, var.region)

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  versioning = { enabled = true }

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  attach_deny_insecure_transport_policy = true

  tags = {
    Name        = "ecs-tfstate"
    environment = var.environment
    Project     = "Terraform-ECS-Platform"
    Owner       = "Jean"
    Managedby   = "Terraform"
  }
}

module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 3.0" 

  name         = "ecs-tf-locks-${var.region}"
  billing_mode = "PAY_PER_REQUEST"

  hash_key   = "LockID"
  attributes = [{ name = "LockID", type = "S" }]

  tags = {
    Name        = "ecs-tf-locks"
    environment = var.environment
    Project     = "Terraform-ECS-Platform"
    Owner       = "Jean"
    Managedby   = "Terraform"
  }
}
