 terraform {
  backend "s3" {}
}

data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

module "deploy_kms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description     = "Encryption key for deploy"
  delimiter       = "_"

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "${var.role}"
  application     = "${var.application}"
  confidentiality = "private"
}

module "s3" {
  source = "git@github.com:crimsonmacaw/terraform-aws-s3.git"
  
  enforce_encryption = ["aws:kms"]
  enable_versioning  = true
  delimiter          = "_"

  environment        = "${var.environment}"
  customer           = "${var.customer}"
  project            = "${var.project}"
  role               = "${var.role}"
  application        = "${var.application}"
}

resource "aws_iam_role" "support_role" {
  name = "${join("_", compact(list(var.environment, var.customer, var.project, var.role, var.application, "support", "iamrole")))}"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
      {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Condition": {
              "Bool": {
                  "aws:MultiFactorAuthPresent": "true"
              },
              "StringEquals": {
                  "sts:ExternalId": "83ce2585-3f6e-4402-b812-6ad7a535687e"
              }
          },
          "Principal": {
              "AWS": "arn:aws:iam::955907688484:root"
          }
      },
      {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Condition": {
              "Bool": {
                  "aws:MultiFactorAuthPresent": "true"
              },
              "StringEquals": {
                  "sts:ExternalId": "c9cda8cc-9004-4310-b2b1-c678f6f5bcb2"
              }
          },
          "Principal": {
              "AWS": "arn:aws:iam::352865010178:root"
          }
      }
  ]
}
EOF

}
