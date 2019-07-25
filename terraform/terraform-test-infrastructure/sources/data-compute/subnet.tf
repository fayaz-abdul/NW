resource "aws_subnet" "subnet" {
  count = "${length(var.subnet_cidr_blocks)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  vpc_id     = "${data.terraform_remote_state.vpc.vpc_id}"
  cidr_block = "${var.subnet_cidr_blocks[count.index]}"

  // Only for test ssh access
  // map_public_ip_on_launch = true

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
        join(var.delimiter, compact(list(var.environment, var.customer, var.project, var.role, var.application, var.subnet_suffixes[count.index],"subnet"))),
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

resource "aws_route_table" "route_table" {
  count = "${length(var.subnet_cidr_blocks)}"

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
        join(var.delimiter, compact(list(var.environment, var.customer, var.project, var.role, var.application, "route_table"))),
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

resource "aws_route_table_association" "subnet_rt_assoc" {
  count = "${length(var.subnet_cidr_blocks)}"

  subnet_id      = "${aws_subnet.subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.route_table.*.id[count.index]}"
}

resource "aws_network_acl" "main" {  
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  subnet_ids = ["${aws_subnet.subnet.*.id}"]

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

