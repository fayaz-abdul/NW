output "all_subnet_ids" {
  value = ["${aws_subnet.subnet.*.id}"]
}


output "all_route_table_ids" {
  value = ["${aws_route_table.route_table.*.id}"]
}
