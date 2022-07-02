resource "azurerm_cdn_profile" "jeeb-uk" {
  name                = "${var.short_prefix}-cdn"
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  location            = var.cdn_location
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "jeeb-uk" {
  name                = "${var.short_prefix}-cdnep"
  profile_name        = azurerm_cdn_profile.jeeb-uk.name
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  location            = var.cdn_location

  origin_host_header = azurerm_storage_account.jeeb-uk.primary_web_host

  is_http_allowed        = true
  is_compression_enabled = true
  
  optimization_type = "GeneralWebDelivery"

  content_types_to_compress = [
    "text/plain",
    "text/html",
    "text/css",
    "text/javascript",
    "application/x-javascript",
    "application/javascript",
    "application/json",
    "application/xml"
  ]

  delivery_rule {
    name  = "httpRedirect"
    order = 1
    request_scheme_condition {
      operator     = "Equal"
      match_values = ["HTTP"]
    }

    url_redirect_action {
      redirect_type = "PermanentRedirect"
      protocol      = "Https"
    }
  }

  delivery_rule {
    name  = "wwwRedirect"
    order = 2
    request_uri_condition {
      operator     = "BeginsWith"
      match_values = ["https://www."]
      transforms   = ["Lowercase"]
    }

    url_redirect_action {
      redirect_type = "PermanentRedirect"
      hostname      = "jeeb.uk"
    }
  }

  origin {
    name      = azurerm_storage_account.jeeb-uk.name
    host_name = azurerm_storage_account.jeeb-uk.primary_web_host
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "jeeb-uk-root" {
  name            = "jeeb-uk-root"
  cdn_endpoint_id = azurerm_cdn_endpoint.jeeb-uk.id
  host_name       = "${azurerm_dns_zone.jeeb-uk.name}"
  user_managed_https {
    key_vault_certificate_id = "${azurerm_key_vault_certificate.jeeb-uk-root.id}"
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "jeeb-uk-www" {
  name            = "jeeb-uk-www"
  cdn_endpoint_id = azurerm_cdn_endpoint.jeeb-uk.id
  host_name       = "${azurerm_dns_cname_record.www.name}.${azurerm_dns_zone.jeeb-uk.name}"
  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
  }
}
