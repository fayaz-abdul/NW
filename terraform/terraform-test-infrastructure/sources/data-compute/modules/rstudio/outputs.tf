output "mount_a" {
  value = "${aws_efs_mount_target.mount_a.id}"
}


output "mount_b" {
  value = "${aws_efs_mount_target.mount_b.id}"
}

output "ecs_cluster_name" {
  value = "${aws_ecs_cluster.cluster.id}"
}

output "container_definitions" {
  value = "${aws_ecs_task_definition.rstudio_task.container_definitions}"
}
