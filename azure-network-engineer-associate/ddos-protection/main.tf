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

variable "ssh-public-key" {
  type = string
}

provider "azurerm" {
  tenant_id       = var.tenant-id
  subscription_id = var.subscription-id
  features {}
}

resource "azurerm_resource_group" "contoso" {
  name     = "MyResourceGroup"
  location = "eastus"
  tags = {
    Description = "azure-network-engineer-associate-learning"
    Contact     = var.contact
  }
}

resource "azurerm_network_ddos_protection_plan" "ddos" {
  name                = "MyDdoSProtectionPlan"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
}

resource "azurerm_virtual_network" "core-services" {
  name                = "MyVirtualNetwork"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  address_space       = ["10.20.0.0/16"]

  ddos_protection_plan {
    enable = true
    id     = azurerm_network_ddos_protection_plan.ddos.id
  }
}

resource "azurerm_subnet" "vm-subnet" {
  name                 = "vm-subnet"
  virtual_network_name = azurerm_virtual_network.core-services.name
  resource_group_name  = azurerm_resource_group.contoso.name

  address_prefixes = ["10.20.0.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "MyPublicIPAddress"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  sku                 = "Standard"
  allocation_method   = "Static"
  domain_name_label   = "mypublicdnsxyz123"

  ddos_protection_plan_id = azurerm_network_ddos_protection_plan.ddos.id
}

resource "azurerm_log_analytics_workspace" "ddos-telemetry" {
  name                = "ddos-telemetry-workspace"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "pip-ddos-telemetry" {
  name                       = "pip-ddos-telemetry"
  target_resource_id         = azurerm_public_ip.pip.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.ddos-telemetry.id

  enabled_metric {
    category = "AllMetrics"
  }

  enabled_log {
    category_group = "allLogs"
  }
}

resource "azurerm_network_interface" "ubuntu" {
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  name                = "ubuntu-nic"

  ip_configuration {
    primary                       = true
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.vm-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_virtual_machine" "ubuntu" {
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location
  name                = "ubuntu"
  vm_size             = "Standard_D2s_v3"

  network_interface_ids = [
    azurerm_network_interface.ubuntu.id
  ]

  storage_os_disk {
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    name              = "ubuntu_osdisk"
    create_option     = "FromImage"
  }

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_profile {
    computer_name  = "ddos-test"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      key_data = var.ssh-public-key
      path     = "/home/azureuser/.ssh/authorized_keys"
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_monitor_metric_alert" "ddos-attack-alert" {
  name                = "ddos-attack-alert"
  resource_group_name = azurerm_resource_group.contoso.name
  scopes              = [azurerm_public_ip.pip.id]
  description         = "Alert when public IP is under DDoS attack"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/publicIPAddresses"
    metric_name      = "IfUnderDDoSAttack"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 0
  }
}
