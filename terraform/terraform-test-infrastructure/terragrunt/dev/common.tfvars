terragrunt = {
  remote_state = {
    backend = "s3"

    config {
      bucket  = "dev-mag-bi-tfstate-${get_env("AWS_DEFAULT_REGION", "eu-west-2")}-${get_aws_account_id()}-s3"
      key     = "${path_relative_to_include()}/terraform.tfstate"
      region  = "${get_env("AWS_DEFAULT_REGION", "eu-west-2")}"
      encrypt = true
    }
  }

  terraform {
    source = "${path_relative_from_include()}/../../sources//${path_relative_to_include()}"

    extra_arguments "common_var" {
      commands = ["${get_terraform_commands_that_need_vars()}"]

      arguments = [
        "-var-file=${get_tfvars_dir()}/${path_relative_from_include()}/common.tfvars",
      ]
    }
  }
}

environment = "dev"
customer    = "mag"
project     = "bi"
