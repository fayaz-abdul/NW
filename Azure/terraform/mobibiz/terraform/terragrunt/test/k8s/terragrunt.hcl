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
    vnet_subnet_id = dependency.vnets.outputs.aks_subnet_id
    agent_count = 1
#    kubernetes_version = "v1.14.8"
    log_analytics_workspace_sku = "PerGB2018"
    ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMSpUINajsgUvEx29Jfqk+1Ed8gEDVXkT7VSRf7vQ/wX4PkqQPK/BsspVeTDVbxMs3TrdgTgLYpA+HhvHpRoUjtseSMGhDY9J5ZtWOVKVnQV0WtoVcPl20FN2S2hjjZX2D0tGl179Ecq9SvnanV7Y9JliczpU2c8zOHXQ2gzwtGRrlrQynVECwgMOMbiO3m8xZ54cixC/7Be5HV7Qdz64JQ28c6KI7seQGs/SXkhB8dFz2DdMPgOJ0kTbKQ2bjUZSufvil+TIMhYaQ0e0YhIYtPExVTVrTbEIISHLvBVTPOw1OeCBDS0OzZa5z5xz0rxxsPcnaggRzQbx6EtjVOhBv terraform@enablemyteam.com"
}
