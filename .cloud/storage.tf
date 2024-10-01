resource "azurerm_storage_account" "jeeb-uk" {
  name                       = "${var.short_prefix}storage"
  resource_group_name        = azurerm_resource_group.jeeb-uk.name
  location                   = azurerm_resource_group.jeeb-uk.location
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  https_traffic_only_enabled = true
  static_website {
    index_document     = "index.html"
    error_404_document = "index.html"
  }

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }
}
