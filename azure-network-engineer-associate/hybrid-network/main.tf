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

variable "psk" {
  type      = string
  sensitive = true
  default   = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
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

resource "azurerm_subnet" "manufacturing-gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.contoso.name
  virtual_network_name = azurerm_virtual_network.manufacturing.name
  address_prefixes     = ["10.30.30.0/27"]
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

resource "azurerm_public_ip" "core-services-gateway-pip" {
  name                = "core-service-gateway-pip"
  location            = azurerm_resource_group.contoso.location
  resource_group_name = azurerm_resource_group.contoso.name
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_version          = "IPv4"
}

resource "azurerm_virtual_network_gateway" "core-services-gateway" {
  name                = "CoreServicesVnetGateway"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"
  generation    = "Generation1"

  ip_configuration {
    name                          = "core-gateway-config"
    public_ip_address_id          = azurerm_public_ip.core-services-gateway-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
}

resource "azurerm_public_ip" "manufacturing-gateway-pip" {
  name                = "manufacturing-gateway-pip"
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.contoso.name
  allocation_method   = "Static"
  sku                 = "Standard"
  ip_version          = "IPv4"
}

resource "azurerm_virtual_network_gateway" "manufacturing-gateway" {
  name                = "ManufacturingVnetGateway"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = "northeurope"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"
  generation    = "Generation1"

  ip_configuration {
    name                          = "manufacturing-gateway-config"
    public_ip_address_id          = azurerm_public_ip.manufacturing-gateway-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.manufacturing-gateway.id
  }
}

resource "azurerm_virtual_network_gateway_connection" "core-to-manufacturing" {
  name                = "core-to-manufacturing"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.core-services-gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.manufacturing-gateway.id

  shared_key = var.psk
}

resource "azurerm_virtual_network_gateway_connection" "manufacturing-to-core" {
  name                = "manufacturing-to-core"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = "northeurope"

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.manufacturing-gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.core-services-gateway.id

  shared_key = var.psk
}
