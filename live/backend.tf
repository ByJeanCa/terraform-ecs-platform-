terraform {
  backend "s3" {
    bucket         = "ecs-tfstate-805206611903-us-east-1"
    dynamodb_table = "ecs-tf-locks-us-east-1"
    key            = ("environments/dev/aws-s3-bucket.tfstate")
    region         = "us-east-1"
  }
}