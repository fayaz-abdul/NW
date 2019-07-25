terragrunt = {
  include {
    path = "${find_in_parent_folders("common.tfvars")}"
  }
}

cidr_base = "172.22.72.0"
cidr_bits = "23"
