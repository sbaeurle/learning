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

variable "admin-username" {
  type = string
}

variable "admin-password" {
  type      = string
  sensitive = true
}

provider "azurerm" {
  tenant_id       = var.tenant-id
  subscription_id = var.subscription-id
  features {}
}

resource "azurerm_resource_group" "contoso" {
  name     = "Test-FW-RG"
  location = "uksouth"
  tags = {
    Description = "azure-network-engineer-associate-learning"
    Contact     = var.contact
  }
}

resource "azurerm_virtual_network" "fw-vnet" {
  name                = "Test-FW-VN"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  address_space       = ["10.0.0.0/16"]

  tags = azurerm_resource_group.contoso.tags
}

resource "azurerm_subnet" "fw-subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.fw-vnet.name
  address_prefixes     = ["10.0.1.0/26"]
}

resource "azurerm_subnet" "workload-subnet" {
  name                 = "Workload-SN"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.fw-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "vm-nic" {
  name                = "Srv-Work-nic"
  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name
  dns_servers         = ["209.244.0.3", "209.244.0.4"]
  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.workload-subnet.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = azurerm_resource_group.contoso.tags
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "Srv-Work"
  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name
  size                = "Standard_D2s_v3"
  admin_username      = var.admin-username
  admin_password      = var.admin-password

  network_interface_ids = [
    azurerm_network_interface.vm-nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.contoso.tags
}

resource "azurerm_public_ip" "fw-pip" {
  name                = "Test-FW01-pip"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  allocation_method   = "Static"
}

resource "azurerm_firewall" "fw" {
  name                = "Test-FW01"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location

  sku_name = "AZFW_VNet"
  sku_tier = "Standard"

  ip_configuration {
    name                 = "default"
    public_ip_address_id = azurerm_public_ip.fw-pip.id
    subnet_id            = azurerm_subnet.fw-subnet.id
  }

  firewall_policy_id = azurerm_firewall_policy.fw-pol.id
}

resource "azurerm_firewall_policy" "fw-pol" {
  name                     = "fw-test-pol"
  resource_group_name      = azurerm_resource_group.contoso.name
  location                 = azurerm_resource_group.contoso.location
  threat_intelligence_mode = "Deny"
}

resource "azurerm_route_table" "rt" {
  name                          = "Firewall-rt"
  resource_group_name           = azurerm_resource_group.contoso.name
  location                      = azurerm_resource_group.contoso.location
  bgp_route_propagation_enabled = true
  route {
    name                   = "Firewall-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "workload-fw" {
  subnet_id      = azurerm_subnet.workload-subnet.id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_firewall_policy_rule_collection_group" "fw-pol-rcg" {
  name               = "fw-test-pol-rcg"
  firewall_policy_id = azurerm_firewall_policy.fw-pol.id
  priority           = 300

  application_rule_collection {
    name     = "App-Coll01"
    priority = 100
    action   = "Allow"
    rule {
      name = "Allow-Google"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = ["www.google.com"]
      source_addresses  = azurerm_subnet.workload-subnet.address_prefixes
    }
  }
  network_rule_collection {
    name     = "Net-Coll01"
    priority = 101
    action   = "Allow"
    rule {
      name                  = "Allow-DNS"
      protocols             = ["UDP"]
      source_addresses      = azurerm_subnet.workload-subnet.address_prefixes
      destination_addresses = ["209.244.0.3", "209.244.0.4"]
      destination_ports     = ["53"]
    }
  }

  nat_rule_collection {
    name     = "NAT-Coll01"
    priority = 102
    action   = "Dnat"

    rule {
      name                = "rdp-nat"
      source_addresses    = ["*"]
      protocols           = ["TCP"]
      destination_ports   = ["3389"]
      destination_address = azurerm_public_ip.fw-pip.ip_address
      translated_address  = azurerm_network_interface.vm-nic.private_ip_address
      translated_port     = "3389"
    }
  }

}
