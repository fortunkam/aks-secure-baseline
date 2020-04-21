resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  dns_prefix          = local.aks_name
  
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    vnet_subnet_id      = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  private_link_enabled = true

  network_profile {
      network_plugin = "azure"      
      load_balancer_sku = "Standard"
    #   service_cidr = "192.168.0.0/16"
    #   dns_service_ip = "192.168.0.10"
    #   docker_bridge_cidr = "172.22.0.1/29"
      outbound_type = "userDefinedRouting"

  }

  role_based_access_control {
      enabled = true
  }
  depends_on = [azurerm_subnet_route_table_association.aks_to_firewall]
}

resource "azurerm_role_assignment" "aksacrpull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}