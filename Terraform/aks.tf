resource "tls_private_key" "aks" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  dns_prefix          = local.aks_name
  kubernetes_version = "1.16.10"
  
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    vnet_subnet_id      = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  private_cluster_enabled = true

  linux_profile {
    admin_username = "AzureAdmin"
    ssh_key  {
      key_data = tls_private_key.aks.public_key_openssh 
    }
  }

  network_profile {
      network_plugin = "azure"      
      load_balancer_sku = "Standard"
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

resource "azurerm_role_assignment" "aks_spoke_contributor" {
  scope                = azurerm_resource_group.spoke.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_spoke_network_contributor" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_managed_identity_operator" {
  scope                = azurerm_kubernetes_cluster.aks.node_resource_group
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_virtual_machine_contributor" {
  scope                = azurerm_kubernetes_cluster.aks.node_resource_group
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
