resource "azurerm_log_analytics_workspace" "jeeb-uk" {
  name                = "${var.short_prefix}-workspace"
  location            = azurerm_resource_group.jeeb-uk.location
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  sku                 = "PerGB2018"
  retention_in_days   = 365
}

resource "azurerm_application_insights" "jeeb-uk" {
  name                = "${var.short_prefix}-appinsights"
  location            = azurerm_resource_group.jeeb-uk.location
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  application_type    = "web"
  retention_in_days   = "365"
}
