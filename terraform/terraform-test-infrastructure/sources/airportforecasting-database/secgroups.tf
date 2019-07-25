resource "aws_security_group" "DbSecGroup" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "Db", "DBsecgroup")))}"
  description = "Control security for Db instances"
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
        join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "Db", "Dbsecgroup"))),
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

resource "aws_security_group_rule" "egress_allow_all" {
  security_group_id        = "${aws_security_group.DbSecGroup.id}"
  type                     = "egress"
  self                     = "true"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow to all traffic with in this group"
}
/*
resource "aws_security_group_rule" "egress_loopback" {
  security_group_id        = "${aws_security_group.DbSecGroup.id}"
  type                     = "egress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  cidr_blocks              = ["127.0.0.1/32"]
  description              = "Allow to all traffic within loopback"
}
*/


resource "aws_security_group_rule" "ingress_allow_all" {
  security_group_id        = "${aws_security_group.DbSecGroup.id}"
  type                     = "ingress"
  self                     = "true"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  description              = "Allow all ports within secgroup"
}

resource "aws_security_group_rule" "ingress_loopback" {
  security_group_id        = "${aws_security_group.DbSecGroup.id}"
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  cidr_blocks              = ["127.0.0.1/32"]
  description              = "Allow all port in loopback"
}

/*
resource "aws_security_group_rule" "ingress_all_selfa" {
  security_group_id        = "${aws_security_group.DbSecGroup.id}"
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  cidr_blocks              = ["127.0.0.1/32"]
  description              = "Allow  ports in Aurorasecgroup"
}
*/

resource "aws_security_group_rule" "ingress_all_selfc" {
  security_group_id        = "${aws_security_group.DbSecGroup.id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  cidr_blocks              = ["10.128.0.0/12"]
  description              = "Allow all port in loopback"
}

resource "aws_security_group_rule" "ingress_all_selfd" {
  security_group_id        = "${aws_security_group.DbSecGroup.id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  cidr_blocks              = ["10.16.0.0/12"]
  description              = "Allow port in Aurorasecgroup"
}

resource "aws_security_group_rule" "ingress_all_selff" {
  security_group_id        = "${aws_security_group.DbSecGroup.id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3306
  to_port                  = 3306
  cidr_blocks              = ["172.22.72.0/23"]
  description              = "Allow port in this Aurorasecgroup"
}

