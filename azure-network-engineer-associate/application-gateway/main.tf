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
  }
}

resource "azurerm_virtual_network" "contoso" {
  name                = "ContosoVNet"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "ag-subnet" {
  name                 = "AGSubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.contoso.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "ag-pip" {
  name                = "AGPublicIPAddress"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  allocation_method   = "Static"
}

resource "azurerm_application_gateway" "gw" {
  name                = "ContosoAppGateway"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location

  sku {
    tier     = "Standard_v2"
    name     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "subnet"
    subnet_id = azurerm_subnet.ag-subnet.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  http_listener {
    name                           = "default"
    frontend_ip_configuration_name = "ag-pip"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  frontend_ip_configuration {
    name                 = "ag-pip"
    public_ip_address_id = azurerm_public_ip.ag-pip.id
  }

  backend_address_pool {
    name         = "BackendPool"
    ip_addresses = azurerm_windows_virtual_machine.vm[*].private_ip_address
  }

  backend_http_settings {
    name                  = "default"
    protocol              = "Http"
    port                  = 80
    cookie_based_affinity = "Disabled"
  }

  request_routing_rule {
    name                       = "RoutingRule"
    http_listener_name         = "default"
    backend_address_pool_name  = "BackendPool"
    backend_http_settings_name = "default"
    rule_type                  = "Basic"
    priority                   = "1000"
  }
}

resource "azurerm_subnet" "backend" {
  name                 = "BackendSubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.contoso.name
  address_prefixes     = ["10.0.1.0/24"]
}
