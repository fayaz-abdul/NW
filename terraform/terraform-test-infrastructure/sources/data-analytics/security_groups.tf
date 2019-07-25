resource "aws_security_group" "redshift" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "redshift", "secgroup")))}"
  description = "Security Group for Redshift Cluster ${var.role} ${var.application}"
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
        join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "redshift", "sec-group"))),
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

# @Todo review the security group rules.
resource "aws_security_group_rule" "public_allow_all_ingress" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.redshift.id}"
}

resource "aws_security_group_rule" "public_allow_all_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.redshift.id}"
}
