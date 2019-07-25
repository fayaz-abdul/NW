output "all_subnet_ids" {
  value = ["${aws_subnet.subnet.*.id}"]
}


output "all_route_table_ids" {
  value = ["${aws_route_table.route_table.*.id}"]
}

output "logstash_mount_a" {
  value = "${module.dc-logstash.mount_a}"
}

output "logstash_mount_b" {
  value = "${module.dc-logstash.mount_b}"
}

output "logstash_ecs_cluster_name" {
  value = "${module.dc-logstash.ecs_cluster_name}"
}

output "rstudio_mount_a" {
  value = "${module.dc-rstudio.mount_a}"
}

output "rstudio_mount_b" {
  value = "${module.dc-rstudio.mount_b}"
}

output "rstudio_ecs_cluster_name" {
  value = "${module.dc-rstudio.ecs_cluster_name}"
}
