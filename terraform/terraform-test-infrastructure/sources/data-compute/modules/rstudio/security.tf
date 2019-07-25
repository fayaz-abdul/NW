resource "aws_security_group" "instance" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "ec2", "secgroup")))}"
  description = "Security Group for rstudio EC2 instances"
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
        join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "ec2", "secgroup"))),
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

# EC2 instance Role

data "aws_iam_policy_document" "iamrole" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "iamrole")))}"
  assume_role_policy = "${data.aws_iam_policy_document.iamrole.json}"
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = "${length(var.iam_policies)}"
  role       = "${aws_iam_role.this.name}"
  policy_arn = "${element(var.iam_policies, count.index)}"
}

resource "aws_iam_instance_profile" "this" {
  name = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "iamprofile")))}"
  role = "${aws_iam_role.this.name}"
}

# Auto Scaling Group Role

resource "aws_iam_service_linked_role" "asg_service_role" {
  aws_service_name = "autoscaling.amazonaws.com"
  custom_suffix  = "rstudio"
}

resource "aws_key_pair" "this" {
  key_name   = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "rstudio", "keypair")))}"
  public_key = "${var.ec2_public_key}"
}

# @Todo review the security group rules.
resource "aws_security_group_rule" "allow_all_ingress" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  cidr_blocks     = ["0.0.0.0/0"]  

  security_group_id = "${aws_security_group.instance.id}"
}

resource "aws_security_group_rule" "allow_all_egress" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  cidr_blocks     = ["0.0.0.0/0"]  

  security_group_id = "${aws_security_group.instance.id}"
}


