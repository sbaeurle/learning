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

resource "azurerm_virtual_network" "core-services" {
  resource_group_name = azurerm_resource_group.contoso.name
  name                = "CoreServicesVnet"
  location            = "eastus"
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "gateway" {
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.core-services.name
  name                 = "GatewaySubnet"
  address_prefixes     = ["10.20.0.0/27"]
}

resource "azurerm_subnet" "shared-services" {
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.core-services.name
  name                 = "SharedServicesSubnet"
  address_prefixes     = ["10.20.10.0/24"]
}

resource "azurerm_subnet" "database" {
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.core-services.name
  name                 = "DatabaseSubnet"
  address_prefixes     = ["10.20.20.0/24"]
}

resource "azurerm_subnet" "public-web-service" {
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.core-services.name
  name                 = "PublicWebServiceSubnet"
  address_prefixes     = ["10.20.30.0/24"]
}

resource "azurerm_virtual_network" "manufacturing" {
  resource_group_name = azurerm_resource_group.contoso.name
  name                = "ManufacturingVnet"
  location            = "westeurope"
  address_space       = ["10.30.0.0/16"]
}

resource "azurerm_subnet" "manufacturing-system" {
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.manufacturing.name
  name                 = "ManufacturingSystemSubnet"
  address_prefixes     = ["10.30.10.0/24"]
}

resource "azurerm_subnet" "sensors-1" {
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.manufacturing.name
  name                 = "SensorSubnet1"
  address_prefixes     = ["10.30.20.0/24"]
}

resource "azurerm_subnet" "sensors-2" {
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.manufacturing.name
  name                 = "SensorSubnet2"
  address_prefixes     = ["10.30.21.0/24"]
}

resource "azurerm_subnet" "sensors-3" {
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.manufacturing.name
  name                 = "SensorSubnet3"
  address_prefixes     = ["10.30.23.0/24"]
}

resource "azurerm_virtual_network" "research" {
  resource_group_name = azurerm_resource_group.contoso.name
  name                = "ResearchVnet"
  location            = "southeastasia"
  address_space       = ["10.40.0.0/16"]
}

resource "azurerm_subnet" "research-system" {
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.research.name
  name                 = "ResearchSystemSubnet"
  address_prefixes     = ["10.40.0.0/24"]
}

resource "azurerm_private_dns_zone" "contoso" {
  resource_group_name = azurerm_resource_group.contoso.name
  name                = "contoso.com"
}

resource "azurerm_private_dns_zone_virtual_network_link" "core-services-link" {
  resource_group_name   = azurerm_resource_group.contoso.name
  private_dns_zone_name = azurerm_private_dns_zone.contoso.name
  virtual_network_id    = azurerm_virtual_network.core-services.id
  name                  = "CoreServicesVnetLink"
  registration_enabled  = true
}

resource "azurerm_network_security_group" "rdp" {
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  name                = "RdpNsg"
  security_rule {
    name                       = "allow-rdp"
    protocol                   = "Tcp"
    priority                   = 1000
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "3389"
    direction                  = "Inbound"
    access                     = "Allow"
  }
}

variable "vm1-name" {
  type = string
}

resource "azurerm_public_ip" "vm1" {
  name                = var.vm1-name
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm1" {
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  name                = "${var.vm1-name}-nic"

  ip_configuration {
    primary                       = true
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.shared-services.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm1-rdp" {
  network_interface_id      = azurerm_network_interface.vm1.id
  network_security_group_id = azurerm_network_security_group.rdp.id
}

resource "random_password" "vm1" {
  length           = 16
  special          = true
  override_special = "!#$%"
}

output "vm1-password" {
  value     = random_password.vm1.result
  sensitive = true
}

resource "azurerm_virtual_machine" "vm1" {
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  name                = var.vm1-name
  vm_size             = "Standard_D2s_v3"

  network_interface_ids = [
    azurerm_network_interface.vm1.id
  ]

  storage_os_disk {
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    name              = "${var.vm1-name}_osdisk"
    create_option     = "FromImage"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  os_profile {
    computer_name  = var.vm1-name
    admin_username = "adminUsername"
    admin_password = random_password.vm1.result
  }

  identity {
    type = "SystemAssigned"
  }
}

variable "vm2-name" {
  type = string
}

resource "azurerm_public_ip" "vm2" {
  name                = var.vm2-name
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm2" {
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  name                = "${var.vm2-name}-nic"

  ip_configuration {
    primary                       = true
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.shared-services.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm2-rdp" {
  network_interface_id      = azurerm_network_interface.vm2.id
  network_security_group_id = azurerm_network_security_group.rdp.id
}

resource "random_password" "vm2" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

output "vm2-password" {
  value     = random_password.vm2.result
  sensitive = true
}

resource "azurerm_virtual_machine" "vm2" {
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  name                = var.vm2-name
  vm_size             = "Standard_D2s_v3"

  network_interface_ids = [
    azurerm_network_interface.vm2.id
  ]

  storage_os_disk {
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    name              = "${var.vm2-name}_osdisk"
    create_option     = "FromImage"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }

  os_profile {
    computer_name  = var.vm2-name
    admin_username = "adminUsername"
    admin_password = random_password.vm2.result
  }

  identity {
    type = "SystemAssigned"
  }
}
