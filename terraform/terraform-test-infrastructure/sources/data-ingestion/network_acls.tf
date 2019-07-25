resource "aws_network_acl" "main" {
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  subnet_ids = ["${aws_subnet.private.*.id}"]

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
        join(var.delimiter, compact(list(var.environment, var.customer, var.project, var.role, var.application, "network","acl"))),
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

resource "aws_network_acl_rule" "private_all_cidr_1_egress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "100"
  egress         = "true"
  protocol       = "-1"
  rule_action    = "allow"
// update this cidr
  cidr_block     = "172.22.72.0/23"
}

resource "aws_network_acl_rule" "private_all_cidr_2_egress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "110"
  egress         = "true"
  protocol       = "-1"
  rule_action    = "allow"
// update this cidr
  cidr_block     = "172.16.0.0/12"
}

resource "aws_network_acl_rule" "private_all_cidr_3_egress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "120"
  egress         = "true"
  protocol       = "-1"
  rule_action    = "allow"
// update this cidr
  cidr_block     = "10.128.0.0/12"
}

resource "aws_network_acl_rule" "private_http_egress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "1000"
  egress         = "true"
  protocol       = "6"
  from_port      = "80"
  to_port        = "80"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_https_egress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "1100"
  egress         = "true"
  protocol       = "6"
  from_port      = "443"
  to_port        = "443"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_custom_udp_egress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "1200"
  egress         = "true"
  protocol       = "17"
  from_port      = "123"
  to_port        = "123"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_all_cidr_4_egress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "2000"
  egress         = "true"
  protocol       = "-1"
  rule_action    = "allow"
//updte this cidr
  cidr_block     = "10.100.0.0/16"
}

resource "aws_network_acl_rule" "private_all_cidr_1_ingress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "100"
  egress         = "false"
  protocol       = "-1"
  rule_action    = "allow"
// update this cidr
  cidr_block     = "172.22.72.0/23"
}

resource "aws_network_acl_rule" "private_all_cidr_2_ingress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "110"
  egress         = "false"
  protocol       = "-1"
  rule_action    = "allow"
// update this cidr
  cidr_block     = "172.16.0.0/12"
}

resource "aws_network_acl_rule" "private_all_cidr_3_ingress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "120"
  egress         = "false"
  protocol       = "-1"
  rule_action    = "allow"
// update this cidr
  cidr_block     = "10.128.0.0/12"
}


resource "aws_network_acl_rule" "private_custom_tcp_ingress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "1000"
  egress         = "false"
  protocol       = "6"
  from_port      = "32768"
  to_port        = "65535"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_custom_udp_1_ingress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "1100"
  egress         = "false"
  protocol       = "17"
  from_port      = "32768"
  to_port        = "65535"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_custom_udp_2_ingress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "1200"
  egress         = "false"
  protocol       = "17"
  from_port      = "123"
  to_port        = "123"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_all_cidr_4_ingress" {
  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "2000"
  egress         = "false"
  protocol       = "-1"
  rule_action    = "allow"
//updte this cidr
  cidr_block     = "10.100.0.0/16"
}

