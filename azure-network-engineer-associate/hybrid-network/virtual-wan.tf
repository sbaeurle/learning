resource "azurerm_virtual_wan" "virtual-wan" {
  name                = "ContosoVirtualWAN"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = azurerm_resource_group.contoso.location

  type = "Standard"
}

resource "azurerm_virtual_hub" "hub1" {
  name                = "ContosoVirtualWANHub-WestUS"
  resource_group_name = azurerm_resource_group.contoso.name
  location            = "westus"
  virtual_wan_id      = azurerm_virtual_wan.virtual-wan.id

  address_prefix = "10.60.0.0/24"
}

// TODO: manually add S2S configuration

resource "azurerm_virtual_hub_connection" "research-vnet" {
  name                      = "ContosoVirtualWAN-to-ResearchVNet"
  virtual_hub_id            = azurerm_virtual_hub.hub1.id
  remote_virtual_network_id = azurerm_virtual_network.research.id
}
