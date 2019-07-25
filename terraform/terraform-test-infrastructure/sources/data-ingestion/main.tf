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

resource "null_resource" "private_subnets" {
  count = "${length(var.private_subnets["indexes"])}"

  triggers {
    newbits           = "${element(var.private_subnets["newbits"], count.index)}"
    index             = "${element(var.private_subnets["indexes"], count.index)}"
    label             = "${element(var.private_subnets["labels"], count.index)}"
    availability_zone = "${element(var.private_subnets["availability_zones"], count.index)}"
  }
}

resource "aws_subnet" "private" {
  count = "${length(var.private_subnets["indexes"])}"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  cidr_block = "${cidrsubnet(
    var.cidr,
    element(null_resource.private_subnets.*.triggers.newbits, count.index),
    element(null_resource.private_subnets.*.triggers.index, count.index)
  )}"

  
  availability_zone = "${join("", list(data.aws_region.this.name, element(null_resource.private_subnets.*.triggers.availability_zone, count.index)))}"

  tags = "${merge(
    var.tags,
    zipmap(
      compact(list(
        "Name",
        var.environment != "" ? "environment" : "",
        var.customer != "" ? "customer" : "",
        var.project != "" ? "project" : "",
        var.role != "" ? "role" : "",
        var.application != "" ? "application" : "",
        "tf:meta"
      )),
      compact(list(
        join(var.delimiter, compact(
          list(
            var.environment,
            var.customer,
            var.project,
            var.role,
            var.application,
            element(null_resource.private_subnets.*.triggers.label, count.index),
            var.private_label,
            element(null_resource.private_subnets.*.triggers.availability_zone, count.index),
            "subnet"
          ))
        ),
        var.environment,
        var.customer,
        var.project,
        var.role,
        var.application,
        "terraform"
      ))
    )
  )}"
}
 
module "kms" {
  source = "git@github.com:crimsonmacaw/terraform-aws-kms.git"

  description            = "Encryption key for data ingestion"
  delimiter              = "_"
  
  environment     = "${var.environment}"
  customer        = "${var.customer}"
  project         = "${var.project}"
  role            = "data"
  application     = "ingestion"
  confidentiality = "private"
}
