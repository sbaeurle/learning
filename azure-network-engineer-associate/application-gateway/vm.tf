variable "vm-size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Virtual machine size"
}

variable "vm-count" {
  type    = number
  default = 2
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

resource "azurerm_network_interface" "vm-nic" {
  count               = var.vm-count
  name                = "vm${count.index}-nic"
  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = azurerm_resource_group.contoso.tags
}

resource "azurerm_windows_virtual_machine" "vm" {
  count               = var.vm-count
  name                = "vm${count.index}"
  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name
  size                = var.vm-size
  admin_username      = var.admin-username
  admin_password      = var.admin-password

  network_interface_ids = [
    azurerm_network_interface.vm-nic[count.index].id,
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

resource "azurerm_virtual_machine_extension" "vm-script-file" {
  count                = var.vm-count
  name                 = "vm${count.index}-script-file-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    fileUris = [
      "https://raw.githubusercontent.com/MicrosoftLearning/AZ-700-Designing-and-Implementing-Microsoft-Azure-Networking-Solutions/refs/heads/master/Allfiles/Exercises/M05/install-iis.ps1"
    ]
    commandToExecute = "powershell.exe -ExecutionPolicy Unrestricted -File install-iis.ps1"
  })

  tags = azurerm_resource_group.contoso.tags
}

output "vm-names" {
  description = "Private addresses"
  value       = azurerm_windows_virtual_machine.vm[*].private_ip_address
}
