terraform {
  backend "s3" {}
}

data "aws_region" "this" {}

data "aws_caller_identity" "this" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "vpc/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}

//sufix private 
//@todo - update all remote state refs
module "hostedzone" {
  source = "git@github.com:crimsonmacaw/terraform-aws-hostedzone.git"

  domain_name = "${var.environment}.${var.project}.${var.customer}.local"

  vpc_ids = ["${data.terraform_remote_state.vpc.vpc_id}"]

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"
}


module "hostedzone_public" {
  source = "git@github.com:crimsonmacaw/terraform-aws-hostedzone.git"

#@todo - change .local to .com
  domain_name = "${var.environment}.${var.project}.${var.customer}.local"

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"
}
