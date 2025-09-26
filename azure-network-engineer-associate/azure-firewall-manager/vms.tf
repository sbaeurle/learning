variable "vm-size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Virtual machine size"
}

variable "admin-username" {
  type        = string
  description = "Admin username for VMs"
}

variable "admin-password" {
  type        = string
  sensitive   = true
  description = "Admin password for VMs"
}

resource "azurerm_network_interface" "vm1-nic" {
  name                = "vm1-nic"
  location            = azurerm_resource_group.fw-manager.location
  resource_group_name = azurerm_resource_group.fw-manager.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.workload-01.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = azurerm_resource_group.fw-manager.tags
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "vm1"
  location            = azurerm_resource_group.fw-manager.location
  resource_group_name = azurerm_resource_group.fw-manager.name
  size                = var.vm-size
  admin_username      = var.admin-username
  admin_password      = var.admin-password

  network_interface_ids = [
    azurerm_network_interface.vm1-nic.id,
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

  tags = azurerm_resource_group.fw-manager.tags
}

resource "azurerm_network_interface" "vm2-nic" {
  name                = "vm2-nice"
  location            = azurerm_resource_group.fw-manager.location
  resource_group_name = azurerm_resource_group.fw-manager.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.workload-02.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = azurerm_resource_group.fw-manager.tags
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "vm2"
  location            = azurerm_resource_group.fw-manager.location
  resource_group_name = azurerm_resource_group.fw-manager.name
  size                = var.vm-size
  admin_username      = var.admin-username
  admin_password      = var.admin-password

  network_interface_ids = [
    azurerm_network_interface.vm2-nic.id,
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

  tags = azurerm_resource_group.fw-manager.tags
}

# Output the private IP addresses for firewall rule configuration
output "vm1-private-ip" {
  description = "Private IP address of VM1 in Spoke-01"
  value       = azurerm_network_interface.vm1-nic.private_ip_address
}

output "vm2-private-ip" {
  description = "Private IP address of VM2 in Spoke-02"
  value       = azurerm_network_interface.vm2-nic.private_ip_address
}
