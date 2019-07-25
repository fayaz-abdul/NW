resource "aws_efs_file_system" "rstudio_mounts" {
  throughput_mode = "bursting"
}

resource "aws_efs_mount_target" "mount_a" {
  file_system_id = "${aws_efs_file_system.rstudio_mounts.id}"
  subnet_id      = "${var.instance_subnet_ids[0]}"
  security_groups = ["${aws_security_group.efs_secgrp.id}"]
}

resource "aws_efs_mount_target" "mount_b" {
  file_system_id = "${aws_efs_file_system.rstudio_mounts.id}"
  subnet_id      = "${var.instance_subnet_ids[1]}"
  security_groups = ["${aws_security_group.efs_secgrp.id}"]
}

resource "aws_security_group" "efs_secgrp" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "efs", "secgroup")))}"
  description = "Control security for RStudio EFS"
  vpc_id      = "${var.vpc_id}"

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
        join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "efs", "secgroup"))),
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

resource "aws_security_group_rule" "allow_all" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  cidr_blocks     = ["127.0.0.1/32"]  

  security_group_id = "${aws_security_group.efs_secgrp.id}"
}

resource "aws_security_group_rule" "allow_nfs" {
  type            = "ingress"
  from_port       = 2049
  to_port         = 2049
  protocol        = "tcp"  

  security_group_id = "${aws_security_group.efs_secgrp.id}"
  source_security_group_id = "${aws_security_group.instance.id}"
}

resource "aws_security_group_rule" "allow_all_efs_egress" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  cidr_blocks     = ["127.0.0.1/32"]  

  security_group_id = "${aws_security_group.efs_secgrp.id}"
}
