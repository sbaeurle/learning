variable "vm-size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Virtual machine size"
}

variable "admin-username" {
  type        = string
  description = "Admin username"
}

variable "admin-password" {
  type        = string
  sensitive   = true
  description = "Admin password"
}

# Public IP Address
resource "azurerm_public_ip" "vm1" {
  name                = "vm1-pip"
  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_version          = "IPv4"

  tags = azurerm_resource_group.contoso.tags
}

# Network Security Group
resource "azurerm_network_security_group" "vm1" {
  name                = "vm1-nsg"
  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name

  security_rule {
    name                       = "default-allow-rdp"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.contoso.tags
}

# Network Interface
resource "azurerm_network_interface" "vm1" {
  name                = "vm1-nic1"
  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.database.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.vm1.id
  }

  tags = azurerm_resource_group.contoso.tags
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "vm1" {
  network_interface_id      = azurerm_network_interface.vm1.id
  network_security_group_id = azurerm_network_security_group.vm1.id
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "vm1" {
  name = "vm1"

  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name
  size                = var.vm-size
  admin_username      = var.admin-username
  admin_password      = var.admin-password

  network_interface_ids = [
    azurerm_network_interface.vm1.id,
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

  tags = azurerm_resource_group.contoso.tags
}
