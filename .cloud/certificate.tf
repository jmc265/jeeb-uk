provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

# resource "acme_registration" "reg" {
#   account_key_pem = "${tls_private_key.private_key.private_key_pem}"
#   email_address   = "${var.email_address}"
# }

# resource "acme_certificate" "jeeb-uk-root" {
#   account_key_pem           = "${acme_registration.reg.account_key_pem}"
#   common_name               = "jeeb.uk"

#   dns_challenge {
#     provider = "azure"
#     config = {
#       AZURE_CLIENT_ID = "${var.azure_client_id}"
#       AZURE_CLIENT_SECRET = "${var.azure_client_secret}"
#       AZURE_SUBSCRIPTION_ID = "${var.azure_subscription_id}"
#       AZURE_TENANT_ID = "${var.azure_tenant_id}"
#       AZURE_RESOURCE_GROUP = "${azurerm_resource_group.jeeb-uk.name}"
#       AZURE_ZONE_NAME = "${azurerm_dns_zone.jeeb-uk.name}"
#     }
#   }
# }

# resource "azurerm_key_vault_certificate" "jeeb-uk-root" {
#   name         = "jeeb-uk-root"
#   key_vault_id = azurerm_key_vault.key-vault.id

#   certificate {
#     contents = "${acme_certificate.jeeb-uk-root.certificate_p12}"
#     password = "${acme_certificate.jeeb-uk-root.certificate_p12_password}"
#   }
# }