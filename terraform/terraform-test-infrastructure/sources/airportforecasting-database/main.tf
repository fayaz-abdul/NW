terraform {
  backend "s3" {}
}

data "aws_region" "this" {}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "this" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "vpc/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}


module "aurora" {
  source = "git@github.com:crimsonmacaw/terraform-aws-aurora.git"
  environment = "${var.environment}"
  customer    = "mag"
  project     = "${var.project}"
  role        = "${var.role}"
  username    = "${var.username}"
  password    = "${var.password}"
  subnet_ids  = ["${aws_subnet.subnet.*.id}"]
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
  kms_key_arn = "${module.Aurorakms.kms_key_arn}"
  db_instance_class = "db.r3.large"
}






module "Aurorakms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description          = "Create the kms keys for the aiportforecasting database"
  delimiter            = "_"
  create_iam_policies  = "false"
  override_policy_json = "${data.aws_iam_policy_document.Aurora_kms.json}"

  include_region_in_name = "true"

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "${var.role}"
  application     = "${join(var.delimiter, compact(list(var.application, "Aurora")))}"
  confidentiality = "private"

}