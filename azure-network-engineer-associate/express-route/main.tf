terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.43.0"
    }
  }
}

variable "tenant-id" {
  type = string
}

variable "subscription-id" {
  type = string
}

variable "contact" {
  type = string
}

provider "azurerm" {
  tenant_id       = var.tenant-id
  subscription_id = var.subscription-id
  features {}
}

resource "azurerm_resource_group" "contoso" {
  name     = "ContosoResourceGroup"
  location = "eastus"
  tags = {
    Description = "azure-network-engineer-associate-learning"
    Contact     = var.contact
    Environment = "learning"
  }
}

resource "azurerm_virtual_network" "core-services" {
  name                = "CoreServicesVnet"
  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name
  address_space       = ["10.20.0.0/16"]

  tags = azurerm_resource_group.contoso.tags
}

resource "azurerm_subnet" "gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.core-services.name
  address_prefixes     = ["10.20.0.0/27"]
}

resource "azurerm_virtual_network_gateway" "core-services-gateway" {
  name                = "CoreServicesVnetGateway"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location

  type = "ExpressRoute"
  sku  = "Standard"

  ip_configuration {
    subnet_id = azurerm_subnet.gateway-subnet.id
  }
}
