include {
  path = find_in_parent_folders()
}

dependency "resourcegroups" {
  config_path = "../resourcegroups"
}

dependency "vnets" {
  config_path = "../vnets"
}

inputs = {
    resource_group_name = dependency.resourcegroups.outputs.resource_group_name
    postgres_subnet_id = dependency.vnets.outputs.postgres_subnet_id
}
