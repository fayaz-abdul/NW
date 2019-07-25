output "simplead_kms" {
  value = "${module.simplead_kms.kms_key_id}"
}

output "ecr_repos" {  
  value = "${aws_ecr_repository.ecr_repos.*.repository_url}"
}