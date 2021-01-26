provider "azurerm" {
  version = "=1.37.0"
}

terraform {
  backend "azurerm" {}
}

resource "random_id" "log_analytics_workspace_name_suffix" {
    byte_length = 8
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
    # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
    name                = join("-", [var.resource_group_name, random_id.log_analytics_workspace_name_suffix.dec])
    location            = var.location
    resource_group_name = var.resource_group_name
    sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "log_analytics_solution" {
    solution_name         = "ContainerInsights"
    location              = azurerm_log_analytics_workspace.log_analytics_workspace.location
    resource_group_name   = var.resource_group_name
    workspace_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
    workspace_name        = azurerm_log_analytics_workspace.log_analytics_workspace.name

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

/*
resource "azurerm_public_ip" "ip" {
  name                = join("-", [var.resource_group_name, "lb-publicip"])
  location            = var.location
  resource_group_name = var.azurerm_resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_lb" "lb" {
  name                = join("-", [var.resource_group_name, "lb"])
  location            = var.location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.ip.id
  }
}
*/

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = join("-", [var.resource_group_name, "k8s"])
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.resource_group_name
#  kubernetes_version  = var.kubernetes_version

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  agent_pool_profile {
    name            = "app"
    #count           = var.agent_count
    count           = 2
    vm_size         = "Standard_DS1_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 10
    vnet_subnet_id     = var.vnet_subnet_id
    type               = "VirtualMachineScaleSets"
    availability_zones = ["1", "2"]
    max_pods           = 250
  }

  agent_pool_profile {
    name            = "mlgpu"
    count           = var.agent_count
    vm_size         = "Standard_DS1_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 10
    vnet_subnet_id     = var.vnet_subnet_id
    type               = "VirtualMachineScaleSets"
    availability_zones = ["1", "2"]
    max_pods           = 250
  }

  agent_pool_profile {
    name            = "mlcpu"
    count           = var.agent_count
    vm_size         = "Standard_DS1_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 10
    vnet_subnet_id     = var.vnet_subnet_id
    type               = "VirtualMachineScaleSets"
    availability_zones = ["1", "2"]
    max_pods           = 250
  }

  agent_pool_profile {
    name            = "es"
    count           = var.agent_count
    vm_size         = "Standard_DS1_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 10
    vnet_subnet_id     = var.vnet_subnet_id
    type               = "VirtualMachineScaleSets"
    availability_zones = ["1", "2"]
    max_pods           = 250
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
      }
  }

  network_profile {
    load_balancer_sku  = "standard"
    network_plugin     = "azure"
#    network_policy     = "calico"
#        dns_service_ip     = "10.0.0.10"
#        docker_bridge_cidr = "172.17.0.1/16"
#        service_cidr       = "10.0.0.0/16"
  }
    
  tags = {
    customer = var.customer
    project = var.project
    environment = var.environment
  }
}
