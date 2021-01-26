resource "azurerm_cdn_profile" "cdn_profile" {
  name                = "${var.cdn_profile_name}-${var.environment}-cdn-profile-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.cdn_profile_sku
  tags = {
    environment = var.environment
    project     = "dataright"
    owner       = "terraform"
    region      = var.location
    tier        = "web"
    costcentre  = ""
  }
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = "${var.cdn_profile_name}-${var.environment}-cdn-endpoint-web"
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  location            = var.location
  resource_group_name = var.resource_group_name
  origin_host_header = "${var.storage_name}.z13.web.core.windows.net"

  origin {
    name      =  "${var.cdn_profile_name}-${var.environment}-cdn-endpoint-origin-web"
    host_name = "${var.storage_name}.z13.web.core.windows.net"

  }

  tags = {
    environment = var.environment
    project     = "dataright"
    owner       = "terraform"
    region      = var.location
    tier        = "web"
    costcentre  = ""
  }
}
