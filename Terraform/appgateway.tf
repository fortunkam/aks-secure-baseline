resource "azurerm_public_ip" "gateway" {
  name                = local.appgateway_publicip
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgateway" {
  name                = local.appgateway
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_V2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = local.appgateway_gateway_ipconfig_name
    subnet_id = azurerm_subnet.appgateway.id
  }

    frontend_port {
    name = local.appgateway_frontend_http_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.appgateway_frontend_ipconfig_name
    public_ip_address_id = azurerm_public_ip.gateway.id
  }

   http_listener {
    name                           = local.appgateway_listener_name
    frontend_ip_configuration_name = local.appgateway_frontend_ipconfig_name
    frontend_port_name             = local.appgateway_frontend_http_port_name
    protocol                       = "Http"
  }

    backend_address_pool {
    name = local.appgateway_backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.appgateway_http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  request_routing_rule {
    name                       = local.appgateway_request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.appgateway_listener_name
    backend_address_pool_name  = local.appgateway_backend_address_pool_name
    backend_http_settings_name = local.appgateway_http_setting_name
  }

}