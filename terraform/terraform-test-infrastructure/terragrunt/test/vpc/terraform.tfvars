terragrunt = {
  include {
    path = "${find_in_parent_folders("common.tfvars")}"
  }
}

cidr_base = "10.0.0.0"
cidr_bits = "23"
