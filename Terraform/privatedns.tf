## Note: Terraform doesn't currently support returning both IP addresses from the private endpoint NIC
## using ARM for the time being.


resource "azurerm_private_dns_zone" "acr" {
  name                = local.acr_dns_zone
  resource_group_name = azurerm_resource_group.spoke.name
  depends_on = [azurerm_container_registry.acr]
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = local.acr_dns_link_hub
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  name                  = local.acr_dns_link_spoke
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "azurerm_private_dns_a_record" "acrdata" {
  name                = regex("(?P<dns>.*)\\.azurecr\\.io",azurerm_private_endpoint.acr.custom_dns_configs[0].fqdn).dns
  zone_name           = azurerm_private_dns_zone.acr.name
  resource_group_name = azurerm_resource_group.spoke.name
  ttl                 = 300
  records             = azurerm_private_endpoint.acr.custom_dns_configs[0].ip_addresses
}

resource "azurerm_private_dns_a_record" "acr" {
  name                = regex("(?P<dns>.*)\\.azurecr\\.io",azurerm_private_endpoint.acr.custom_dns_configs[1].fqdn).dns
  zone_name           = azurerm_private_dns_zone.acr.name
  resource_group_name = azurerm_resource_group.spoke.name
  ttl                 = 300
  records             = azurerm_private_endpoint.acr.custom_dns_configs[1].ip_addresses
}

resource "azurerm_private_dns_zone" "sql" {
  name                = local.sql_dns_zone
  resource_group_name = azurerm_resource_group.spoke.name
  depends_on = [azurerm_sql_server.sql]
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_sql" {
  name                  = local.sql_dns_link_hub
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_sql" {
  name                  = local.sql_dns_link_spoke
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "azurerm_private_dns_a_record" "sql" {
  name                = azurerm_sql_server.sql.name
  zone_name           = azurerm_private_dns_zone.sql.name
  resource_group_name = azurerm_resource_group.spoke.name
  ttl                 = 300
  records             = [ azurerm_private_endpoint.sql.private_service_connection[0].private_ip_address ]
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = local.keyvault_dns_zone
  resource_group_name = azurerm_resource_group.spoke.name
  depends_on = [azurerm_key_vault.aks_keyvault]
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_kv" {
  name                  = local.keyvault_dns_link_hub
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.hub.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_kv" {
  name                  = local.keyvault_dns_link_spoke
  resource_group_name   = azurerm_resource_group.spoke.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "azurerm_private_dns_a_record" "keyvault" {
  name                = azurerm_key_vault.aks_keyvault.name
  zone_name           = azurerm_private_dns_zone.keyvault.name
  resource_group_name = azurerm_resource_group.spoke.name
  ttl                 = 300
  records             = [ azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address ]
}