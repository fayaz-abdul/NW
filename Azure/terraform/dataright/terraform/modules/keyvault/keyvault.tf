data "azurerm_client_config" "current" {}


resource "azurerm_key_vault" "key_vault" {
  name                        = "${var.keyvault-name}-${var.environment}-key-vault"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify"

    ]
    secret_permissions = [
      "get",
      "list",
      "backup",
      "delete",
      "purge",
      "recover",
      "restore",
      "set",
    ]

    storage_permissions = [
      "get",
      "list",
      "backup",
      "delete",
      "purge",
      "recover",
      "restore",
      "set",
    ]
  }

  tags = {
    environment = var.environment
    project     = "dataright"
    owner       = "terraform"
    region      = var.location
    tier        = "security"
    costcentre  = ""
  }
}

resource "azurerm_key_vault_access_policy" "key_vault_access_policy" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = var.function_app_tenant_id
  object_id    = var.function_app_principal_id

  key_permissions = [
    "decrypt",
    "get",
    "list"
  ]

  secret_permissions = [
    "get",
    "list"
  ]

}

data "azurerm_subscription" "primary" {
}

resource "azurerm_role_definition" "role_definition" {
  name  = "${var.keyvault-name}-${var.environment}-role-definition"
  scope = data.azurerm_subscription.primary.id

  permissions {
    actions     = ["Microsoft.Resources/subscriptions/resourceGroups/read"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id,
  ]

}


resource "azurerm_role_assignment" "role_assignment" {
  scope                = azurerm_key_vault.key_vault.id
  principal_id         = var.function_app_principal_id
  role_definition_name = azurerm_role_definition.role_definition.name
}
