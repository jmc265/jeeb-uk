resource "azurerm_key_vault" "key-vault" {
  name                        = "${var.short_prefix}-key-vault"
  location                    = azurerm_resource_group.jeeb-uk.location
  resource_group_name         = azurerm_resource_group.jeeb-uk.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.azure_tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.key-vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Get",
    "Import",
    "Update",
    "Delete",
    "Purge"
  ]

  key_permissions = [
    "Get"
  ]

  secret_permissions  = [
    "Get"
  ]
}
