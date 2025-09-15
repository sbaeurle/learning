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

variable "core-services_vnet_name" {
  type        = string
  default     = "CoreServicesVnet"
  description = "Name of the Core Services Virtual Network"
}

variable "manufacturing_vnet_name" {
  type        = string
  default     = "ManufacturingVnet"
  description = "Name of the Manufacturing Virtual Network"
}

variable "research_vnet_name" {
  type        = string
  default     = "ResearchVnet"
  description = "Name of the Research Virtual Network"
}

provider "azurerm" {
  tenant_id       = var.tenant-id
  subscription_id = var.subscription-id
  features {}
}

resource "azurerm_resource_group" "contoso" {
  name     = "ContosoResourceGroup"
  location = "eastus"
  tags = {
    Description = "azure-network-engineer-associate-learning"
    Contact     = var.contact
    Environment = "learning"
  }
}

# Core Services Virtual Network (East US)
resource "azurerm_virtual_network" "core-services" {
  name                = var.core-services_vnet_name
  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name
  address_space       = ["10.20.0.0/16"]

  tags = azurerm_resource_group.contoso.tags
}

# Core Services Subnets
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.core-services.name
  address_prefixes     = ["10.20.0.0/27"]
}

resource "azurerm_subnet" "shared-services" {
  name                 = "SharedServicesSubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.core-services.name
  address_prefixes     = ["10.20.10.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "DatabaseSubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.core-services.name
  address_prefixes     = ["10.20.20.0/24"]
}

resource "azurerm_subnet" "public-web-service" {
  name                 = "PublicWebServiceSubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.core-services.name
  address_prefixes     = ["10.20.30.0/24"]
}

# Manufacturing Virtual Network (North Europe)
resource "azurerm_virtual_network" "manufacturing" {
  name                = var.manufacturing_vnet_name
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.contoso.name
  address_space       = ["10.30.0.0/16"]

  tags = azurerm_resource_group.contoso.tags
}

# Manufacturing Subnets
resource "azurerm_subnet" "manufacturing-system" {
  name                 = "ManufacturingSystemSubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.manufacturing.name
  address_prefixes     = ["10.30.10.0/24"]
}

resource "azurerm_subnet" "sensor-1" {
  name                 = "SensorSubnet1"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.manufacturing.name
  address_prefixes     = ["10.30.20.0/24"]
}

resource "azurerm_subnet" "sensor-2" {
  name                 = "SensorSubnet2"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.manufacturing.name
  address_prefixes     = ["10.30.21.0/24"]
}

resource "azurerm_subnet" "sensor-3" {
  name                 = "SensorSubnet3"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.manufacturing.name
  address_prefixes     = ["10.30.22.0/24"]
}

# Research Virtual Network (Southeast Asia)
resource "azurerm_virtual_network" "research" {
  name                = var.research_vnet_name
  location            = "southeastasia"
  resource_group_name = azurerm_resource_group.contoso.name
  address_space       = ["10.40.0.0/16"]

  tags = azurerm_resource_group.contoso.tags
}

# Research Subnets
resource "azurerm_subnet" "research-system" {
  name                 = "ResearchSystemSubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.research.name
  address_prefixes     = ["10.40.40.0/24"]
}
