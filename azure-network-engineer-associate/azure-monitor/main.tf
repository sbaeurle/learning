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

provider "azurerm" {
  tenant_id       = var.tenant-id
  subscription_id = var.subscription-id
  features {}
}

data "azurerm_resource_group" "lb-rg" {
  name = "IntLB-RG"
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "log-space"
  resource_group_name = data.azurerm_resource_group.lb-rg.name
  location            = data.azurerm_resource_group.lb-rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

data "azurerm_lb" "backend-lb" {
  name                = "backend-lb"
  resource_group_name = data.azurerm_resource_group.lb-rg.name
}

# Diagnostic Settings to connect Load Balancer to Analytics Workspace
resource "azurerm_monitor_diagnostic_setting" "lb_diagnostics" {
  name                       = "lb-diagnostics"
  target_resource_id         = data.azurerm_lb.backend-lb.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  # Enable Load Balancer metrics
  enabled_log {
    category_group = "allLogs"
  }

  # Enable metrics
  enabled_metric {
    category = "AllMetrics"
  }
}


