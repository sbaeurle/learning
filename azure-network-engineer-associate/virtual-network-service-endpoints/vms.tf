variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Virtual machine size"
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Admin username"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password"
}

# Public IP for VM1 (Public subnet)
resource "azurerm_public_ip" "contoso_public_ip" {
  name                = "public-vm-pip"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP for VM2 (Private subnet)
resource "azurerm_public_ip" "contoso_private_ip" {
  name                = "private-vm-pip"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NSG for public subnet VM
resource "azurerm_network_security_group" "public-nsg" {
  name                = "public-nsg"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location

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
}

# NSG for private subnet VM
resource "azurerm_network_security_group" "private-rdp-nsg" {
  name                = "private-rdp-nsg"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location

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
}

resource "azurerm_network_interface" "public-nic" {
  name                = "public-vm-nic"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.contoso_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "public-nic-nsg" {
  network_interface_id      = azurerm_network_interface.public-nic.id
  network_security_group_id = azurerm_network_security_group.public-nsg.id
}

resource "azurerm_network_interface" "private-nic" {
  name                = "private-vm-nic"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.contoso_private_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "private-nic-nsg" {
  network_interface_id      = azurerm_network_interface.private-nic.id
  network_security_group_id = azurerm_network_security_group.private-nsg.id
}

resource "azurerm_windows_virtual_machine" "public-vm" {
  name                = "public-vm"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.public-nic.id,
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
}

resource "azurerm_windows_virtual_machine" "private-vm" {
  name                = "private-vm"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.private-nic.id,
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
}
