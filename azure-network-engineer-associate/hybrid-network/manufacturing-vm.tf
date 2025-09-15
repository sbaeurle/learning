resource "azurerm_public_ip" "manufacturing-vm" {
  name                = "vm2-pip"
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.contoso.name
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_version          = "IPv4"

  tags = azurerm_resource_group.contoso.tags
}

resource "azurerm_network_security_group" "manufacturing-vm" {
  name                = "vm2-pip"
  location            = "northeurope"
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

resource "azurerm_network_interface" "manufacturing-vm" {
  name                = "vm2-pip"
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.contoso.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.manufacturing-system.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.manufacturing-vm.id
  }

  tags = azurerm_resource_group.contoso.tags
}

resource "azurerm_network_interface_security_group_association" "manufacturing-vm" {
  network_interface_id      = azurerm_network_interface.manufacturing-vm.id
  network_security_group_id = azurerm_network_security_group.manufacturing-vm.id
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "manufacturing-vm" {
  name                = "vm2"
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.contoso.name
  size                = var.vm-size
  admin_username      = var.admin-username
  admin_password      = var.admin-password

  network_interface_ids = [
    azurerm_network_interface.manufacturing-vm.id,
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
