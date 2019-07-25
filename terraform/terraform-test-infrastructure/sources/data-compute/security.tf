resource "aws_network_acl_rule" "acl_rules" {
  count = "${length(var.network_acls)}"

  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "${lookup(var.network_acls[count.index],"RuleNumber")}"
  egress         = "${lookup(var.network_acls[count.index],"Egress")}"
  protocol       = "${lookup(var.network_acls[count.index],"Protocol")}"
  rule_action    = "${lookup(var.network_acls[count.index],"RuleAction")}"
  cidr_block     = "${lookup(var.network_acls[count.index],"CidrBlock")}"
}

# @Todo review the acl rules.
resource "aws_network_acl_rule" "acl_rules_port" {
  count = "${length(var.network_acls_port)}"

  network_acl_id = "${aws_network_acl.main.id}"
  rule_number    = "${lookup(var.network_acls_port[count.index],"RuleNumber")}"
  egress         = "${lookup(var.network_acls_port[count.index],"Egress")}"
  protocol       = "${lookup(var.network_acls_port[count.index],"Protocol")}"
  rule_action    = "${lookup(var.network_acls_port[count.index],"RuleAction")}"
  cidr_block     = "${lookup(var.network_acls_port[count.index],"CidrBlock")}"
  from_port      = "${lookup(var.network_acls_port[count.index],"From")}"
  to_port        = "${lookup(var.network_acls_port[count.index],"To")}"
}
