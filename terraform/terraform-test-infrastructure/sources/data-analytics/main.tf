terraform {
  backend "s3" {}
}

data "aws_region" "this" {}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "this" {}

data "terraform_remote_state" "zone" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "domain/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "vpc/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}

data "terraform_remote_state" "vpc_endpoint_s3" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "vpc/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}

module "analytics_kinesiskms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description            = "Create the kms keys for kinesis Data Analytics"
  delimiter              = "_"
  create_iam_policies    = "false"
  override_policy_json   = "${data.aws_iam_policy_document.kms_firehouse.json}"
  include_region_in_name = "${var.analytics_include_region_in_name}"

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "${var.role}"
  application     = "${join(var.delimiter, compact(list(var.application, "kinesis")))}"
  confidentiality = "private"
}

module "analytics_redshiftkms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description            = "Create the kms keys for the Redshift Data Analytics"
  delimiter              = "_"
  create_iam_policies    = "false"
  override_policy_json   = "${data.aws_iam_policy_document.redshift_kms.json}"
  include_region_in_name = "${var.analytics_include_region_in_name}"

  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "${var.role}"
  application     = "${join(var.delimiter, compact(list(var.application, "redshift")))}"
  confidentiality = "private"
}

module "analytics_source_s3copybucket" {
  source = "git@github.com:crimsonmacaw/terraform-aws-s3.git"

  create_iam_policies = "${var.s3_module_create_iam_policies}"
  enforce_encryption  = ["aws:kms"]
  enable_versioning   = true
  delimiter           = "_"

  include_region_in_name = false

  environment = "${var.environment}"
  customer    = "${var.customer}"
  project     = "${var.project}"
  role        = "${var.role}"
  application = "${var.application}"
  suffix      = "sourcecopybucket"
}

module "analytics_module_redshift" {
  source = "git@github.com:crimsonmacaw/tf-redshift-infrastructure.git//modules/redshift?ref=test"

  #TO DO EIP attachment

  dbpass               = "${var.analytics_redshift_password}"
  subnet_ids           = ["${aws_subnet.subnet.*.id}"]
  publicly_accessible  = "${var.analytics_redshift_publicly_accessible}"
  eip_accessible       = "${var.analytics_redshift_eip_accessible}"
  node_type            = "${var.analytics_redshift_cluster_node_type}"
  number_nodes         = "${var.analytics_redshift_cluster_number_of_nodes}"
  cluster_version      = "${var.analytics_redshift_cluster_version}"
  redshift_secgroup_id = "${aws_security_group.redshift.id}"
  cluster_iam_roles    = ["${aws_iam_role.redshiftrole.arn}"]
  kms_key_id           = "${module.analytics_redshiftkms.kms_key_arn}"
  enabled_logging      = "${var.analytics_redshift_enabled_logging}"
  environment          = "${var.environment}"
  customer             = "${var.customer}"
  project              = "${var.project}"
  role                 = "${var.role}"
  application          = "${var.application}"
}

#To Do Route53 DNS entries 

