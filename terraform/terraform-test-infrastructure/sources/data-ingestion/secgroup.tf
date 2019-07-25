resource "aws_security_group" "DmsSecGroup" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "Dms", "secgroup")))}"
  description = "Control security for DMS instances"
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
        join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "Dms", "secgroup"))),
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

resource "aws_security_group_rule" "egress_all_self" {
  security_group_id        = "${aws_security_group.DmsSecGroup.id}"
  type                     = "egress"
  self                     = "true"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow to all traffic with in this group"
}

resource "aws_security_group_rule" "egress_loopback" {
  security_group_id        = "${aws_security_group.DmsSecGroup.id}"
  type                     = "egress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  cidr_blocks              = ["127.0.0.1/32"]
  description              = "Allow to all traffic within loopback"
}

/*
resource "aws_security_group_rule" "egress_redshift" {
  security_group_id        = "${aws_security_group.DmsSecGroup.id}"
  type                     = "egress"
  protocol                 = "6"
  from_port                = "5439"
  to_port                  = "5439"
// need to mention data_store redshift security group below
//  source_security_group_id = ""
  description              = "Allow to all through redshift port"
}

resource "aws_security_group_rule" "egress_custom_redshift" {
  security_group_id        = "${aws_security_group.DmsSecGroup.id}"
  type                     = "egress"
  protocol                 = "6"
  from_port                = "5746"
  to_port                  = "5746"
// need to mention data_store redshift security group below
//  source_security_group_id = ""
  
  description              = "Allow to this custom port"
}
*/

resource "aws_security_group_rule" "ingress_all_self" {
  security_group_id        = "${aws_security_group.DmsSecGroup.id}"
  type                     = "ingress"
  self                     = "true"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow all ports within secgroup"
}

resource "aws_security_group_rule" "ingress_loopback" {
  security_group_id        = "${aws_security_group.DmsSecGroup.id}"
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  cidr_blocks              = ["127.0.0.1/32"]
  description              = "Allow all port in loopback"
}
