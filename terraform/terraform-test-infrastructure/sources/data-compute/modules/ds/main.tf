terraform {
  backend "s3" {}
}

data "aws_region" "this" {}

