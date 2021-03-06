terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "james-cx"

    workspaces {
      name = "jeeb-uk"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "jeeb-uk" {
  name     = "jeeb-uk"
  location = "uksouth"
}
