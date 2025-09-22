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

resource "azurerm_resource_group" "rg-eu" {
  name     = "rg-eu"
  location = "eastus"

  tags = {
    Description = "azure-network-engineer-associate-learning"
    Contact     = var.contact
  }
}

resource "azurerm_service_plan" "s1-asp-eu" {
  name                = "ContosoAppServicePlanEastUS"
  resource_group_name = azurerm_resource_group.rg-eu.name
  location            = azurerm_resource_group.rg-eu.location
  sku_name            = "S1"
  os_type             = "Windows"
}

resource "azurerm_log_analytics_workspace" "workspace-eu" {
  name                = "ContosoLogSpaceEastUs"
  resource_group_name = azurerm_resource_group.rg-eu.name
  location            = azurerm_resource_group.rg-eu.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "insights-eu" {
  name                = "ContosoAppInsightsEastUS"
  location            = azurerm_resource_group.rg-eu.location
  resource_group_name = azurerm_resource_group.rg-eu.name
  workspace_id        = azurerm_log_analytics_workspace.workspace-eu.id
  application_type    = "web"
}

resource "azurerm_windows_web_app" "windows-web-app-eu" {
  name                = "ContosoWebAppEastUSXY"
  resource_group_name = azurerm_resource_group.rg-eu.name
  location            = azurerm_resource_group.rg-eu.location
  service_plan_id     = azurerm_service_plan.s1-asp-eu.id

  site_config {

  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.insights-eu.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.insights-eu.connection_string
  }
}

resource "azurerm_resource_group" "rg-cu" {
  name     = "rg-cu"
  location = "centralus"

  tags = {
    Description = "azure-network-engineer-associate-learning"
    Contact     = var.contact
  }
}

resource "azurerm_service_plan" "s1-asp-cu" {
  name                = "ContosoAppServicePlanCentralUS"
  resource_group_name = azurerm_resource_group.rg-cu.name
  location            = azurerm_resource_group.rg-cu.location
  sku_name            = "S1"
  os_type             = "Windows"
}

resource "azurerm_log_analytics_workspace" "workspace-cu" {
  name                = "ContosoLogSpaceCentralUs"
  resource_group_name = azurerm_resource_group.rg-cu.name
  location            = azurerm_resource_group.rg-cu.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "insights-cu" {
  name                = "ContosoAppInsightsCentralUS"
  location            = azurerm_resource_group.rg-cu.location
  resource_group_name = azurerm_resource_group.rg-cu.name
  workspace_id        = azurerm_log_analytics_workspace.workspace-eu.id
  application_type    = "web"
}

resource "azurerm_windows_web_app" "windows-web-app-cu" {
  name                = "ContosoWebAppCentralUSXY"
  resource_group_name = azurerm_resource_group.rg-cu.name
  location            = azurerm_resource_group.rg-cu.location
  service_plan_id     = azurerm_service_plan.s1-asp-cu.id

  site_config {

  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.insights-cu.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.insights-cu.connection_string
  }
}
