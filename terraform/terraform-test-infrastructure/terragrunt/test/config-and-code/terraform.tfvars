terragrunt = {
  include {
    path = "${find_in_parent_folders("common.tfvars")}"
  }
  prevent_destroy = true
}

ecr_repo_names = [
  "test_crimson_bi_data_compute_ecr/logstash_ftp",
  "test_crimson_bi_data_compute_ecr/logstash_jdbc",
  "test_crimson_bi_data_compute_ecr/logstash_scheduler",
  "test_crimson_bi_data_compute_ecr/logstash_stomp",
  "test_crimson_bi_data_analytics_ecr/r_studio"
]