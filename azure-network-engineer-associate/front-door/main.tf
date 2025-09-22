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

  lifecycle {
    ignore_changes = [tags]
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

  lifecycle {
    ignore_changes = [tags]
  }

}


resource "azurerm_cdn_frontdoor_profile" "front-door" {
  name                = "FrontDoorXY"
  resource_group_name = azurerm_resource_group.rg-cu.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "fd" {
  name                     = "FDendpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front-door.id
}

resource "azurerm_cdn_frontdoor_origin_group" "default" {
  name                     = "default-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front-door.id
  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 5
    successful_samples_required        = 4
  }
}

resource "azurerm_cdn_frontdoor_origin" "as-cu" {
  name                           = "central-us-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.default.id
  enabled                        = true
  host_name                      = azurerm_windows_web_app.windows-web-app-cu.default_hostname
  certificate_name_check_enabled = true
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_windows_web_app.windows-web-app-cu.default_hostname
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_origin" "as-eu" {
  name                           = "east-us-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.default.id
  enabled                        = true
  host_name                      = azurerm_windows_web_app.windows-web-app-eu.default_hostname
  certificate_name_check_enabled = true
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_windows_web_app.windows-web-app-eu.default_hostname
  priority                       = 1
  weight                         = 1000
}

resource "azurerm_cdn_frontdoor_route" "default" {
  name                          = "default"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.default.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.as-cu.id, azurerm_cdn_frontdoor_origin.as-eu.id]

  enabled             = true
  patterns_to_match   = ["/*"]
  supported_protocols = ["Http", "Https"]
}
