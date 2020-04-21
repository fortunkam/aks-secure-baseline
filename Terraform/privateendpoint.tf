resource "azurerm_private_endpoint" "acr" {
  name                = local.acr_private_endpoint
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  subnet_id           = azurerm_subnet.acr.id

  private_service_connection {
    name                           = local.acr_private_link
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names = [ "registry" ]
  }
  
}