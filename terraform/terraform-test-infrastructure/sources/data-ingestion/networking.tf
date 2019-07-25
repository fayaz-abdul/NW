resource "aws_eip" "private" {
  count = "${var.enable_nat_gateways ? length(var.nat_gateway_subnets) : 0}"
  vpc   = true

  tags = "${merge(
    var.tags,
    zipmap(
      compact(list(
        "Name",
        var.environment != "" ? "environment" : "",
        var.customer != "" ? "customer" : "",
        var.project != "" ? "project" : "",
        "tf:meta"
      )),
      compact(list(
        join(var.delimiter, compact(list(var.environment, var.customer, var.project, "eip"))),
        var.environment,
        var.customer,
        var.project,
        "terraform"
      ))
    )
  )}"
}

resource "aws_nat_gateway" "private" {
  count = "${var.enable_nat_gateways ? length(var.nat_gateway_subnets) : 0}"

  allocation_id = "${element(aws_eip.private.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.private.*.id, element(var.nat_gateway_subnets, count.index))}"

//  private_ip = "${}"
  tags = "${merge(
    var.tags,
    zipmap(
      compact(list(
        "Name",
        var.environment != "" ? "environment" : "",
        var.customer != "" ? "customer" : "",
        var.project != "" ? "project" : "",
        "tf:meta"
      )),
      compact(list(
        join(var.delimiter, compact(list(var.environment, var.customer, var.project, "ngw", element(null_resource.private_subnets.*.triggers.availability_zone, count.index)))),
        var.environment,
        var.customer,
        var.project,
        "terraform"
      ))
    )
  )}"
}
