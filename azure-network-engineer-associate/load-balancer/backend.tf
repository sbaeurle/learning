variable "vm-count" {
  type        = number
  description = "Number of VMs to create"
  default     = 3
}

variable "vm-size" {
  type        = string
  description = "Virtual machine size"
  default     = "Standard_D2s_v3"
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

# Network Security Group for backend VMs
resource "azurerm_network_security_group" "backend-nsg" {
  name                = "myNSG"
  location            = azurerm_resource_group.lb-group.location
  resource_group_name = azurerm_resource_group.lb-group.name

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

  security_rule {
    name                       = "allow-http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = azurerm_resource_group.lb-group.tags
}

# Network Interfaces for backend VMs
resource "azurerm_network_interface" "backend-vm-nics" {
  count               = var.vm-count
  name                = "backend-nic-${count.index + 1}"
  location            = azurerm_resource_group.lb-group.location
  resource_group_name = azurerm_resource_group.lb-group.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.backend-subnet.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = azurerm_resource_group.lb-group.tags
}

# Associate NSG with Network Interfaces
resource "azurerm_network_interface_security_group_association" "backend-vm-nsg-associations" {
  count                     = var.vm-count
  network_interface_id      = azurerm_network_interface.backend-vm-nics[count.index].id
  network_security_group_id = azurerm_network_security_group.backend-nsg.id
}

# Backend Virtual Machines
resource "azurerm_windows_virtual_machine" "backend-vms" {
  count               = var.vm-count
  name                = "backend-${count.index + 1}"
  location            = azurerm_resource_group.lb-group.location
  resource_group_name = azurerm_resource_group.lb-group.name
  size                = var.vm-size
  admin_username      = var.admin-username
  admin_password      = var.admin-password

  network_interface_ids = [
    azurerm_network_interface.backend-vm-nics[count.index].id,
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

# IIS Installation Extension for backend VMs
resource "azurerm_virtual_machine_extension" "backend-vm-iis" {
  count                = var.vm-count
  name                 = "VMConfig"
  virtual_machine_id   = azurerm_windows_virtual_machine.backend-vms[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    fileUris = [
      "https://raw.githubusercontent.com/MicrosoftLearning/AZ-700-Designing-and-Implementing-Microsoft-Azure-Networking-Solutions/master/Allfiles/Exercises/M04/install-iis.ps1"
    ]
    commandToExecute = "powershell.exe -ExecutionPolicy Unrestricted -File install-iis.ps1"
  })

  tags = azurerm_resource_group.lb-group.tags
}

# Output the private IP addresses of backend VMs
output "backend-vm-private-ips" {
  description = "Private IP addresses of backend VMs"
  value       = azurerm_network_interface.backend-vm-nics[*].private_ip_address
}

# Output the VM names for reference
output "backend-vm-names" {
  description = "Names of the backend VMs"
  value       = azurerm_windows_virtual_machine.backend-vms[*].name
}
