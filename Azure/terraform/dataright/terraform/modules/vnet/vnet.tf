resource "azurerm_virtual_network" "virtual_network" {
  name                = "${var.virtual_network_name}-${var.environment}-virtual-network"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.virtual_network_address_space]
  # subnet {
  #   name           = "subnet1"
  #   address_prefix = "10.0.1.0/24"
  # }
  # subnet {
  #   name           = "subnet2"
  #   address_prefix = "10.0.2.0/24"
  # }

  tags = {
    environment = var.environment
    project     = "dataright"
    owner       = "terraform"
    region      = var.location
    tier        = "vnet"
    costcentre  = ""
  }
}

resource "azurerm_subnet" "subnet_postgre" {
  name                 = "${var.virtual_network_name}-${var.environment}-subnet-postgre"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes       = [var.subnet_postgre_address_prefixes]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "subnet_functionapp" {
  name                 = "${var.virtual_network_name}-${var.environment}-subnet-functionapp"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes       = [var.subnet_functionapp_address_prefixes]
  delegation {
    name = "${var.virtual_network_name}-${var.environment}-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}


output "postgres_subnet_id" {
  value = azurerm_subnet.subnet_postgre.id
}

output "functionapp_subnet_id" {
  value = azurerm_subnet.subnet_functionapp.id
}

# output "subnet_id_postgres" {
#   value = flatten(azurerm_virtual_network.virtual_network.subnet)
# }
