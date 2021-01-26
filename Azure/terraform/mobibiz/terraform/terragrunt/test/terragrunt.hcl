remote_state {
  backend = "azurerm"
  config = {
    storage_account_name = "emtterraform"
    container_name       = "test-terraform-state"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}

locals {
  default_yaml_path = "common.yaml"
}

terraform {
  source = "${path_relative_from_include()}/../../sources//${path_relative_to_include()}"

  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()

    required_var_files = [
      "${get_parent_terragrunt_dir()}/common.tfvars"
    ]

  }
}
