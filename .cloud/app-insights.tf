resource "azurerm_application_insights" "jeeb-uk" {
  name                = "${var.short_prefix}-appinsights"
  location            = azurerm_resource_group.jeeb-uk.location
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  application_type    = "web"
  retention_in_days   = "365"
}

output "app_insights_connection_string" {
  value = azurerm_application_insights.jeeb-uk.connection_string
}