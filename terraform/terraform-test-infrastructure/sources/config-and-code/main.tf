 terraform {
  backend "s3" {}
}

data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

module "simplead_kms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description     = "Encryption key for simple AD password"
  delimiter       = "_"

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "network"
  application     = "backend"
  confidentiality = "private"
}

# For data compute component, which uses ECS for logstash.
resource "aws_ecr_repository" "ecr_repos" {
  count = "${length(var.ecr_repo_names)}"

  name = "${var.ecr_repo_names[count.index]}"
}