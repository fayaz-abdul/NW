resource "aws_security_group" "sftp_secgroup" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "sftp-elb", "secgroup")))}"
  description = "Control security for Data Store SFTP Server ELB"
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
        join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "sftp", "elb-secgroup"))),
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

resource "aws_security_group_rule" "ingress_loopback" {
  security_group_id        = "${aws_security_group.sftp_secgroup.id}"
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  cidr_blocks              = ["127.0.0.1/32"]
  description              = "Allow all port in loopback"
}

resource "aws_security_group_rule" "ingress_ssh" {
  security_group_id        = "${aws_security_group.sftp_secgroup.id}"
  type                     = "ingress"
  protocol                 = "6"
  from_port                = "22"
  to_port                  = "22"
  cidr_blocks              = ["86.183.105.57/32"]
  description              = "Allow tcp 22 port from mentioned source cidr"
}


resource "aws_security_group_rule" "egress_loopback" {
  security_group_id        = "${aws_security_group.sftp_secgroup.id}"
  type                     = "egress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  cidr_blocks              = ["127.0.0.1/32"]
  description              = "Allow to all traffic within loopback"
}

/*

//aws_security_group_rule.egress_ssh_2222: One of ['cidr_blocks', 'ipv6_cidr_blocks', 'self', 'source_security_group_id', 'prefix_list_ids'] must be set to create an AWS Security Group Rule

resource "aws_security_group_rule" "egress_ssh" {
  security_group_id        = "${aws_security_group.sftp_secgroup.id}"
  type                     = "egress"
  protocol                 = "6"
  from_port                = "22"
  to_port                  = "22"
// need to mention data_store sftp secgroup
//  source_security_group_id = ""
  description              = "Allow tcp 22 port"
}

resource "aws_security_group_rule" "egress_ssh_2222" {
  security_group_id        = "${aws_security_group.sftp_secgroup.id}"
  type                     = "egress"
  protocol                 = "6"
  from_port                = "2222"
  to_port                  = "2222"
// need to mention data_store sftp secgroup
//  source_security_group_id = ""
  description              = "Allow tcp 2222 port"
}

*/