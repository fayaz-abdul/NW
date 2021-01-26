include {
  path = find_in_parent_folders()
}

dependency "resourcegroups" {
  config_path = "../resourcegroups"
}

inputs = {
    resource_group_name = dependency.resourcegroups.outputs.resource_group_name
    vnet_address_space = ["172.18.0.0/16"]
    aks_subnet_address = "172.18.0.0/19"
    postgres_subnet_address = "172.18.32.0/24"
    elastic_subnet_address = "172.18.33.0/24"
}
