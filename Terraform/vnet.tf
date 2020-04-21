resource "azurerm_virtual_network" "hub" {
  name                = local.vnet_hub_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = [local.vnet_hub_iprange]
}

resource "azurerm_subnet" "firewall" {
  name                 = local.firewall_subnet
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefix       = local.firewall_subnet_iprange
}

resource "azurerm_subnet" "buildagent" {
  name                 = local.buildagent_subnet
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefix       = local.buildagent_subnet_iprange
}
resource "azurerm_subnet" "deployagent" {
  name                 = local.deployagent_subnet
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefix       = local.deployagent_subnet_iprange
}

resource "azurerm_subnet" "bastion" {
  name                 = local.bastion_subnet
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefix       = local.bastion_subnet_iprange
}

resource "azurerm_virtual_network" "spoke" {
  name                = local.vnet_spoke_name
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = [local.vnet_spoke_iprange]
}

resource "azurerm_subnet" "aks" {
  name                 = local.aks_subnet
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefix       = local.aks_subnet_iprange
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "acr" {
  name                 = local.acr_subnet
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefix       = local.acr_subnet_iprange
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_route_table" "aks" {
  name                          = local.firewall_route_table_name
  location                      = azurerm_resource_group.spoke.location
  resource_group_name           = azurerm_resource_group.spoke.name
  disable_bgp_route_propagation = false

  route {
    name           = local.firewall_route_name
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "aks_to_firewall" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.aks.id
}

resource "azurerm_virtual_network_peering" "hubtospoke" {
  name                      = local.hub_to_spoke_vnet_peer
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
}

resource "azurerm_virtual_network_peering" "spoketohub" {
  name                      = local.spoke_to_hub_vnet_peer
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
}