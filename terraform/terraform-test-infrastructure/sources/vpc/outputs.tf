output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_endpoint_s3_id" {
  value = "${module.vpc.vpc_endpoint_s3_id}"
}

output "vpc_endpoint_s3_prefixlist" {
  value = "${module.vpc.vpc_endpoint_s3_prefixlist}"
}

output "vpc_endpoint_s3_cidr" {
  value = "${module.vpc.vpc_endpoint_s3_cidr}"
}

output "vpc_endpoint_dynamodb_id" {
  value = "${module.vpc.vpc_endpoint_dynamodb_id}"
}

output "vpc_endpoint_dynamodb_prefixlist" {
  value = "${module.vpc.vpc_endpoint_dynamodb_prefixlist}"
}

output "vpc_endpoint_dynamodb_cidr" {
  value = "${module.vpc.vpc_endpoint_dynamodb_cidr}"
}

output "public_subnet_ids" {
  value = ["${module.vpc.public_subnet_ids}"]
}

output "public_route_table_ids" {
  value = ["${module.vpc.public_route_table_ids}"]
}

output "public_network_acl_ids" {
  value = ["${module.vpc.public_network_acl_ids}"]
}

output "private_subnet_ids" {
  value = ["${module.vpc.private_subnet_ids}"]
}

output "private_route_table_ids" {
  value = ["${module.vpc.private_route_table_ids}"]
}

output "private_network_acl_ids" {
  value = ["${module.vpc.private_network_acl_ids}"]
}
