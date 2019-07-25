terragrunt = {
  include {
    path = "${find_in_parent_folders("common.tfvars")}"
  }

  dependencies {
    paths = ["../vpc", "../domain"]
  }
}

role            = "network"
application     = "dmz"
