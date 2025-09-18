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

resource "azurerm_resource_group" "lb-group" {
  name     = "IntLB-RG"
  location = "eastus"

  tags = {
    Description = "azure-network-engineer-associate-learning"
    Contact     = var.contact
  }
}

resource "azurerm_virtual_network" "lb-net" {
  name                = "IntLB-VNet"
  resource_group_name = azurerm_resource_group.lb-group.name
  location            = azurerm_resource_group.lb-group.location
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.lb-group.name
  virtual_network_name = azurerm_virtual_network.lb-net.name

  address_prefixes = ["10.1.244.0/24"]
}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "bastion-pip"
  resource_group_name = azurerm_resource_group.lb-group.name
  location            = azurerm_virtual_network.lb-net.location
  allocation_method   = "Static"
}

resource "azurerm_bastion_host" "bastion-host" {
  name                = "myBastionHost"
  resource_group_name = azurerm_resource_group.lb-group.name
  location            = azurerm_virtual_network.lb-net.location

  ip_configuration {
    name                 = "bastion-configuration"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}

resource "azurerm_subnet" "backend-subnet" {
  name                 = "myBackendSubnet"
  resource_group_name  = azurerm_resource_group.lb-group.name
  virtual_network_name = azurerm_virtual_network.lb-net.name

  address_prefixes = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "frontend-subnet" {
  name                 = "myFrontendSubnet"
  resource_group_name  = azurerm_resource_group.lb-group.name
  virtual_network_name = azurerm_virtual_network.lb-net.name

  address_prefixes = ["10.1.2.0/24"]
}
