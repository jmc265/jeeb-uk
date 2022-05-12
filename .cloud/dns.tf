resource "azurerm_dns_zone" "jeeb-uk" {
  name                = "jeeb.uk"
  resource_group_name = azurerm_resource_group.jeeb-uk.name

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_dns_cname_record" "www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.jeeb-uk.name
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  ttl                 = 300
  target_resource_id  = azurerm_cdn_endpoint.jeeb-uk.id
}

resource "azurerm_dns_a_record" "jeeb-uk-root" {
  name                = "@"
  zone_name           = azurerm_dns_zone.jeeb-uk.name
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  ttl                 = 300
  target_resource_id  = azurerm_cdn_endpoint.jeeb-uk.id
}

resource "azurerm_dns_cname_record" "jeeb-uk-root-cdnverify" {
  name                = "cdnverify"
  zone_name           = azurerm_dns_zone.jeeb-uk.name
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  ttl                 = 300
  record              = "cdnverify.${azurerm_cdn_endpoint.jeeb-uk.name}.azureedge.net"
}

resource "azurerm_dns_mx_record" "jeeb-uk-email" {
  name                = "@"
  zone_name           = azurerm_dns_zone.jeeb-uk.name
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  ttl                 = 300
  record {
    preference = 10
    exchange   = "mx1.privateemail.com"
  }

  record {
    preference = 10
    exchange   = "mx2.privateemail.com"
  }
}

resource "azurerm_dns_txt_record" "jeeb-uk-email" {
  name                = "@"
  zone_name           = azurerm_dns_zone.jeeb-uk.name
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  ttl                 = 300
  record {
    value = "v=spf1 include:spf.privateemail.com ~all"
  }
}

resource "azurerm_dns_cname_record" "jeeb-uk-mail" {
  name                = "mail"
  zone_name           = azurerm_dns_zone.jeeb-uk.name
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  ttl                 = 300
  record              = "privateemail.com"
}

resource "azurerm_dns_cname_record" "jeeb-uk-autodiscover" {
  name                = "autodiscover"
  zone_name           = azurerm_dns_zone.jeeb-uk.name
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  ttl                 = 300
  record              = "privateemail.com"
}

resource "azurerm_dns_cname_record" "jeeb-uk-autoconfig" {
  name                = "autoconfig"
  zone_name           = azurerm_dns_zone.jeeb-uk.name
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  ttl                 = 300
  record              = "privateemail.com"
}

resource "azurerm_dns_srv_record" {
  name                = "_autodiscover"
  zone_name           = azurerm_dns_zone.jeeb-uk.name
  resource_group_name = azurerm_resource_group.jeeb-uk.name
  ttl                 = 300

  record {
    priority = 0
    weight   = 0
    port     = 443
    target   = "privateemail.com"
  }
}

output "name_servers" {
  value = azurerm_dns_zone.jeeb-uk.name_servers
}