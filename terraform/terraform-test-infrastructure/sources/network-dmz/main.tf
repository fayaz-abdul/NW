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


data "terraform_remote_state" "hostedzone_public" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "domain/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}
resource "aws_security_group" "elb" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "network-dmz", "elb", "secgroup")))}"
  description = "Security Group for network-dmz ELB"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

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
        join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "network-dmz", "ec2", "secgroup"))),
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

resource "aws_security_group_rule" "instance_outbound_internet" {
  security_group_id = "${aws_security_group.elb.id}"
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound internet"
}

resource "aws_elb" "sftp_loadbalancer" {
  name               = "sftp-elb"
  subnets            = ["${aws_subnet.public.*.id}"]
  cross_zone_load_balancing = true
  listener {
    instance_port     = 22
    instance_protocol = "TCP"
    lb_port           = 22
    lb_protocol       = "TCP"
  }
}

resource "aws_route53_record" "sftp_record" {
  zone_id = "${data.terraform_remote_state.hostedzone_public.hostedzone_id_public}"
//@todo change this to .com
  name    = "sftp.${var.environment}.${var.project}.${var.customer}.local"
  type    = "A"

  alias {
    name                   = "${aws_elb.sftp_loadbalancer.dns_name}"
    zone_id                = "${aws_elb.sftp_loadbalancer.zone_id}"
    evaluate_target_health = true
  }
}

resource "null_resource" "public_subnets" {
  count = "${length(var.public_subnets["indexes"])}"

  triggers {
    newbits           = "${element(var.public_subnets["newbits"], count.index)}"
    index             = "${element(var.public_subnets["indexes"], count.index)}"
    label             = "${element(var.public_subnets["labels"], count.index)}"
    availability_zone = "${element(var.public_subnets["availability_zones"], count.index)}"
  }
}

resource "aws_subnet" "public" {
  count = "${length(var.public_subnets["indexes"])}"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  cidr_block = "${cidrsubnet(
    var.cidr,
    element(null_resource.public_subnets.*.triggers.newbits, count.index),
    element(null_resource.public_subnets.*.triggers.index, count.index)
  )}"

  
  availability_zone = "${join("", list(data.aws_region.this.name, element(null_resource.public_subnets.*.triggers.availability_zone, count.index)))}"

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
            element(null_resource.public_subnets.*.triggers.label, count.index),
            var.public_label,
            element(null_resource.public_subnets.*.triggers.availability_zone, count.index),
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

/*
module "openvpn" {
  source = "git@github.com:crimsonmacaw/terraform-aws-openvpn.git"

  vpc_id             = "${data.terraform_remote_state.vpc.vpc_id}"
  subnet_ids         = ["${aws_subnet.public.*.id}"]
  ec2_public_key     = "${var.openvpn_ec2_public_key}"
  vpc_endpoint_s3_id = "${data.terraform_remote_state.vpc.vpc_endpoint_s3_id}"
  
  environment = "test"
  customer    = "crimson"
  project     = "bi"
  role        = "network"
  application = "dmz"
} 
*/
