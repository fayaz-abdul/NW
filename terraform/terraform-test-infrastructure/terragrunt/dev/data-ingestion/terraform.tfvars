terragrunt = {
  include {
    path = "${find_in_parent_folders("common.tfvars")}"
  }
}

subnet_cidr_blocks = [
  "10.0.0.192/27",
  "10.0.0.224/27"
]

role            = "data"
application     = "ingestion"
