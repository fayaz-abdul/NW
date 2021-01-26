include {
  path = find_in_parent_folders()
}

dependency "resourcegroups" {
  config_path = "../resourcegroups"
}

inputs = {
    resource_group_name = dependency.resourcegroups.outputs.resource_group_name
}
