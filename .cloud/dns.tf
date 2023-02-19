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

# resource "azurerm_dns_cname_record" "jeeb-uk-root-cdnverify" {
#   name                = "cdnverify"
#   zone_name           = azurerm_dns_zone.jeeb-uk.name
#   resource_group_name = azurerm_resource_group.jeeb-uk.name
#   ttl                 = 300
#   record              = "cdnverify.${azurerm_cdn_endpoint.jeeb-uk.name}.azureedge.net"
# }

output "name_servers" {
  value = azurerm_dns_zone.jeeb-uk.name_servers
}