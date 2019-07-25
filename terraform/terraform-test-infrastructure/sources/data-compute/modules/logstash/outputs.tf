output "mount_a" {
  value = "${aws_efs_mount_target.mount_a.id}"
}


output "mount_b" {
  value = "${aws_efs_mount_target.mount_b.id}"
}

output "ecs_cluster_name" {
  value = "${aws_ecs_cluster.cluster.id}"
}
