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
            var.public_label,
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
*/

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
            var.public_label,
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
  count = "${length(aws_subnet.public.0.cidr_block)}"

  subnet_id      = "${aws_subnet.public.0.id}"
  route_table_id = "${aws_route_table.a_route_table.id}"
}

resource "aws_route_table_association" "subnetBRouteBassociation" {
  count = "${length(aws_subnet.public.0.cidr_block)}"

  subnet_id      = "${aws_subnet.public.1.id}"
  route_table_id = "${aws_route_table.b_route_table.id}"
}

