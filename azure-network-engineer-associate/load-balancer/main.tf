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

  address_prefixes = ["10.1.1.0/24"]
}

resource "azurerm_network_interface" "test-vm-nic" {
  name                = "test-vm-nic"
  resource_group_name = azurerm_resource_group.lb-group.name
  location            = azurerm_resource_group.lb-group.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.backend-subnet.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = azurerm_resource_group.lb-group.tags
}

resource "azurerm_network_interface_security_group_association" "test-vm-nsg-asc" {
  network_interface_id      = azurerm_network_interface.test-vm-nic.id
  network_security_group_id = azurerm_network_security_group.backend-nsg.id
}

# Backend Virtual Machines
resource "azurerm_windows_virtual_machine" "test-vm" {
  name                = "test-vm"
  resource_group_name = azurerm_resource_group.lb-group.name
  location            = azurerm_resource_group.lb-group.location
  size                = var.vm-size
  admin_username      = var.admin-username
  admin_password      = var.admin-password

  network_interface_ids = [
    azurerm_network_interface.test-vm-nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.lb-group.tags
}
