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

moved {
  from = azurerm_resource_group.contoso
  to   = azurerm_resource_group.fw-manager
}

resource "azurerm_resource_group" "fw-manager" {
  name     = "fw-manager-rg"
  location = "uksouth"
  tags = {
    Description = "azure-network-engineer-associate-learning"
    Contact     = var.contact
  }
}

resource "azurerm_virtual_network" "spoke-01" {
  name                = "spoke-01"
  resource_group_name = azurerm_resource_group.fw-manager.name
  location            = azurerm_resource_group.fw-manager.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "workload-01" {
  name                 = "sn-workload-01"
  resource_group_name  = azurerm_resource_group.fw-manager.name
  virtual_network_name = azurerm_virtual_network.spoke-01.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "spoke-02" {
  name                = "spoke-02"
  resource_group_name = azurerm_resource_group.fw-manager.name
  location            = azurerm_resource_group.fw-manager.location
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "workload-02" {
  name                 = "sn-workload-02"
  resource_group_name  = azurerm_resource_group.fw-manager.name
  virtual_network_name = azurerm_virtual_network.spoke-02.name
  address_prefixes     = ["10.1.1.0/24"]
}

data "azurerm_virtual_hub" "hub" {
  name                = "hub"
  resource_group_name = azurerm_resource_group.fw-manager.name
}

resource "azurerm_virtual_hub_connection" "hub-spoke-01" {
  name                      = "hub-spoke-01"
  virtual_hub_id            = data.azurerm_virtual_hub.hub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke-01.id
}

resource "azurerm_virtual_hub_connection" "hub-spoke-02" {
  name                      = "hub-spoke-02"
  virtual_hub_id            = data.azurerm_virtual_hub.hub.id
  remote_virtual_network_id = azurerm_virtual_network.spoke-02.id
}

resource "azurerm_firewall_policy" "policy-01" {
  name                = "policy-01"
  resource_group_name = azurerm_resource_group.fw-manager.name
  location            = azurerm_resource_group.fw-manager.location
}

resource "azurerm_firewall_policy_rule_collection_group" "fw-pol-rcg" {
  name               = "fw-test-pol-rcg"
  firewall_policy_id = azurerm_firewall_policy.policy-01.id
  priority           = 300

  application_rule_collection {
    name     = "app-rc-ß1"
    priority = 100
    action   = "Allow"
    rule {
      name = "Allow-Microsoft"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = ["*.microsoft.com"]
      source_addresses  = ["*"]
    }
  }

  nat_rule_collection {
    name     = "dnat-rdp"
    priority = 102
    action   = "Dnat"

    rule {
      name                = "allow-rdp"
      source_addresses    = ["*"]
      protocols           = ["TCP"]
      destination_ports   = ["3389"]
      destination_address = "172.167.147.31"
      translated_address  = azurerm_network_interface.vm1-nic.private_ip_address
      translated_port     = "3389"
    }
  }

  network_rule_collection {
    name     = "vnet-rdp"
    priority = 101
    action   = "Allow"
    rule {
      name                  = "allow-vnet"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = azurerm_virtual_network.spoke-02.address_space
      destination_ports     = ["3389"]
    }
  }
}
