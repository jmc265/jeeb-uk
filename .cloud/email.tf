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

resource "azurerm_dns_srv_record" "jeeb-uk-autodiscover" {
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