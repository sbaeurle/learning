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

resource "azurerm_resource_group" "tm1-group-eu" {
  name     = "Contoso-RG-TM1"
  location = "eastus"

  tags = {
    Description = "azure-network-engineer-associate-learning"
    Contact     = var.contact
  }
}

resource "azurerm_service_plan" "s1-asp-eu" {
  name                = "ContosoAppServicePlanEastUS"
  resource_group_name = azurerm_resource_group.tm1-group-eu.name
  location            = azurerm_resource_group.tm1-group-eu.location
  sku_name            = "S1"
  os_type             = "Windows"
}

resource "azurerm_log_analytics_workspace" "workspace-eu" {
  name                = "ContosoLogSpaceEastUs"
  resource_group_name = azurerm_resource_group.tm1-group-eu.name
  location            = azurerm_resource_group.tm1-group-eu.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "insights-eu" {
  name                = "ContosoAppInsightsEastUS"
  location            = azurerm_resource_group.tm1-group-eu.location
  resource_group_name = azurerm_resource_group.tm1-group-eu.name
  workspace_id        = azurerm_log_analytics_workspace.workspace-eu.id
  application_type    = "web"
}

resource "azurerm_windows_web_app" "windows-web-app-eu" {
  name                = "ContosoWebAppEastUSXY"
  resource_group_name = azurerm_resource_group.tm1-group-eu.name
  location            = azurerm_resource_group.tm1-group-eu.location
  service_plan_id     = azurerm_service_plan.s1-asp-eu.id

  site_config {}

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.insights-eu.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.insights-eu.connection_string
  }
}

resource "azurerm_resource_group" "tm2-group-we" {
  name     = "Contoso-RG-TM2"
  location = "westeurope"

  tags = {
    Description = "azure-network-engineer-associate-learning"
    Contact     = var.contact
  }
}

resource "azurerm_service_plan" "s1-asp-we" {
  name                = "ContosoAppServicePlanWestEurope"
  resource_group_name = azurerm_resource_group.tm2-group-we.name
  location            = azurerm_resource_group.tm2-group-we.location
  sku_name            = "S1"
  os_type             = "Windows"
}

resource "azurerm_log_analytics_workspace" "workspace-we" {
  name                = "ContosoLogSpaceWestEurope"
  resource_group_name = azurerm_resource_group.tm2-group-we.name
  location            = azurerm_resource_group.tm2-group-we.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "insights-we" {
  name                = "ContosoAppInsightsWestEurope"
  location            = azurerm_resource_group.tm2-group-we.location
  resource_group_name = azurerm_resource_group.tm2-group-we.name
  workspace_id        = azurerm_log_analytics_workspace.workspace-we.id
  application_type    = "web"
}

resource "azurerm_windows_web_app" "windows-web-app-we" {
  name                = "ContosoWebAppWestEuropeXY"
  resource_group_name = azurerm_resource_group.tm2-group-we.name
  location            = azurerm_resource_group.tm2-group-we.location
  service_plan_id     = azurerm_service_plan.s1-asp-we.id

  site_config {}

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.insights-we.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.insights-we.connection_string
  }
}
