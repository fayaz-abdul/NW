output "deploy_kms" {
  value = "${module.deploy_kms.kms_key_id}"
}

output "s3" {
  value = "${module.s3.s3_bucket_id}"
}
