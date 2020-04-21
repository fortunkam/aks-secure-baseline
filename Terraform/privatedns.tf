## Note: Terraform doesn't currently support returning both IP addresses from the private endpoint NIC
## using ARM for the time being.


# resource "azurerm_private_dns_zone" "acr" {
#   name                = local.acr_dns_zone
#   resource_group_name = azurerm_resource_group.spoke.name
#   depends_on = [azurerm_container_registry.acr]
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
#   name                  = local.acr_dns_link_hub
#   resource_group_name   = azurerm_resource_group.spoke.name
#   private_dns_zone_name = azurerm_private_dns_zone.acr.name
#   virtual_network_id    = azurerm_virtual_network.hub.id
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
#   name                  = local.acr_dns_link_spoke
#   resource_group_name   = azurerm_resource_group.spoke.name
#   private_dns_zone_name = azurerm_private_dns_zone.acr.name
#   virtual_network_id    = azurerm_virtual_network.spoke.id
# }

# resource "azurerm_private_dns_a_record" "acr" {
#   name                = azurerm_container_registry.acr.name
#   zone_name           = azurerm_private_dns_zone.acr.name
#   resource_group_name = azurerm_resource_group.spoke.name
#   ttl                 = 300
#   records             = [ azurerm_private_endpoint.acr.private_service_connection[0].private_ip_address ]
# }

# resource "azurerm_private_dns_a_record" "acrdata" {
#   name                = "${azurerm_container_registry.acr.name}.${azurerm_resource_group.spoke.location}.data"
#   zone_name           = azurerm_private_dns_zone.acr.name
#   resource_group_name = azurerm_resource_group.spoke.name
#   ttl                 = 300
#   records             = [ azurerm_private_endpoint.acr.private_service_connection[0].private_ip_address ]
# }

resource "azurerm_template_deployment" "getResourceNames" {
    name            = "getResourceNames"
    resource_group_name = azurerm_resource_group.spoke.name
    template_body = file("${path.module}/ARM/getResourceNames.json")
     parameters = {
        "privateEndpointId" = azurerm_private_endpoint.acr.id
        "aksId" = azurerm_kubernetes_cluster.aks.id
    }
    deployment_mode = "Incremental"
}

resource "azurerm_template_deployment" "deployPrivateDns" {
    name            = "deployPrivateDns"
    resource_group_name = azurerm_resource_group.spoke.name
    template_body = file("${path.module}/ARM/privatedns.json")
     parameters = {
        "acr_name" = azurerm_container_registry.acr.name
        "acr_location" = azurerm_resource_group.spoke.location
        "acr_privateendpoint_network_interface_id" = azurerm_template_deployment.getResourceNames.outputs["networkInterface"]
        "vnet_hub_id" = azurerm_virtual_network.hub.id
        "vnet_spoke_id" = azurerm_virtual_network.spoke.id      
    }
    deployment_mode = "Incremental"
}

resource "azurerm_template_deployment" "deployAKSPrivateDNSHubVnetLink" {
    name            = "deployAKSPrivateDNSHubVnetLink"
    resource_group_name = azurerm_template_deployment.getResourceNames.outputs["aksResourceGroup"]
    template_body = file("${path.module}/ARM/aks_privatedns.json")
     parameters = {
        "privatedns_aks_zone_name" = regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}\\.privatelink\\.${azurerm_resource_group.spoke.location}\\.azmk8s\\.io", azurerm_template_deployment.getResourceNames.outputs["aksPrivateDNSName"])
        "vnet_hub_id" = azurerm_virtual_network.hub.id
    }
    deployment_mode = "Incremental"
    depends_on = [azurerm_kubernetes_cluster.aks]
}