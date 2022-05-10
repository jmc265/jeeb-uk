variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription Id"
}

variable "azure_client_id" {
  type        = string
  description = "Azure Client Id/appId"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure Client Id/appId"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure Tenant Id"
}

variable "short_prefix" {
  type    = string
  default = "jeeb"
}

variable "cdn_location" {
  default = "westeurope"
}

variable "email_address" {
  default = "jamescross265@gmail.com"
}