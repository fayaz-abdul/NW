terragrunt = {
  include {
    path = "${find_in_parent_folders("common.tfvars")}"
  }  
}

role = "airportforecasting"
application = "deploy"
