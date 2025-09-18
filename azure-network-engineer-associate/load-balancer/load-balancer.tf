resource "azurerm_lb" "backend-lb" {
  name                = "backend-lb"
  resource_group_name = azurerm_resource_group.lb-group.name
  location            = azurerm_resource_group.lb-group.location

  sku = "Standard"

  frontend_ip_configuration {
    name                          = "backend-lb-frontend"
    subnet_id                     = azurerm_subnet.frontend-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

moved {
  from = azurerm_lb_backend_address_pool.lb-backend-pool
  to   = azurerm_lb_backend_address_pool.backend-pool
}

resource "azurerm_lb_backend_address_pool" "backend-pool" {
  name            = "lb-backend-pool"
  loadbalancer_id = azurerm_lb.backend-lb.id
}

resource "azurerm_network_interface_backend_address_pool_association" "vm-backend-association" {
  count                   = var.vm-count
  network_interface_id    = azurerm_network_interface.backend-vm-nics[count.index].id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend-pool.id
}

resource "azurerm_lb_probe" "backend-probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.backend-lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
}

resource "azurerm_lb_rule" "backend-rule" {
  name            = "http-rule"
  loadbalancer_id = azurerm_lb.backend-lb.id
  protocol        = "Tcp"
  frontend_port   = "80"
  backend_port    = "80"

  frontend_ip_configuration_name = azurerm_lb.backend-lb.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.backend-probe.id
  idle_timeout_in_minutes        = 15
  floating_ip_enabled            = false
}

output "lb-ip" {
  value = azurerm_lb.backend-lb.frontend_ip_configuration[0].private_ip_address
}
