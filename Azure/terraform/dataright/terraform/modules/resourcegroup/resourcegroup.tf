
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group_name}-${var.environment}-resource-group"
  location = var.location
  tags = {
    environment = var.environment
    project     = "dataright"
    owner       = "terraform"
    region      = var.location
    tier        = "classification"
    costcentre  = ""
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.resource_group.name
}