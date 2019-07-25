terraform {
  backend "s3" {}
}

data "terraform_remote_state" "network-dmz" {
  backend = "s3"

  config {
    bucket = "${var.environment}-${var.customer}-${var.project}-tfstate-${data.aws_region.this.name}-${data.aws_caller_identity.this.account_id}-s3"
    key    = "network-dmz/terraform.tfstate"
    region = "${data.aws_region.this.name}"
  }
}


resource "aws_route_table" "a_route_table" {
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"


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
            var.private_label,
            "a_route_table"
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
resource "aws_route" "route_a" {
  route_table_id            = "${aws_route_table.a_route_table.id}"
// change this cidr
  destination_cidr_block    = "172.22.72.0/23"
  vpc_peering_connection_id = "pcx-45ff3dc1"
}


resource "aws_route" "private" {
  count = "${var.enable_nat_gateways ? length(var.nat_gateway_subnets) > 0 ? length(var.private_subnets["indexes"]) : 0 : 0}"

  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.public.*.id, count.index)}"
}
*/

resource "aws_route" "route_a_dmz" {
  //count = "${var.enable_nat_gateways ? length(var.nat_gateway_subnets) > 0 ? length(var.private_subnets["indexes"]) : 0 : 0}"

  route_table_id            = "${aws_route_table.a_route_table.id}"
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = "${data.terraform_remote_state.network-dmz.nat_gateway_ids[0]}"
}

resource "aws_route" "route_b_dmz" {
  //count = "${var.enable_nat_gateways ? length(var.nat_gateway_subnets) > 0 ? length(var.private_subnets["indexes"]) : 0 : 0}"

  route_table_id            = "${aws_route_table.b_route_table.id}"
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = "${data.terraform_remote_state.network-dmz.nat_gateway_ids[1]}"
}



resource "aws_route_table" "b_route_table" {
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

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
            var.private_label,
            "b_route_table"
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
resource "aws_route" "route_b" {
  route_table_id            = "${aws_route_table.b_route_table.id}"
// change this cidr
  destination_cidr_block    = "172.22.72.0/23"
  vpc_peering_connection_id = "pcx-45ff3dc1"
}
*/

resource "aws_route_table_association" "subnetARouteAassociation" {
  count = "${length(aws_subnet.private.0.cidr_block)}"

  subnet_id      = "${aws_subnet.private.0.id}"
  route_table_id = "${aws_route_table.a_route_table.id}"
}

resource "aws_route_table_association" "subnetBRouteBassociation" {
  count = "${length(aws_subnet.private.0.cidr_block)}"

  subnet_id      = "${aws_subnet.private.1.id}"
  route_table_id = "${aws_route_table.b_route_table.id}"
}

