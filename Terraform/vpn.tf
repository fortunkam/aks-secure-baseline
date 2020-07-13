resource "azurerm_public_ip" "vpn" {
  name                = local.vpn_publicip
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "vpn" {
    name                        = local.vpn_name
    location                    = azurerm_resource_group.hub.location
    resource_group_name         = azurerm_resource_group.hub.name

    sku                         = "VpnGw1"
    type                        = "Vpn"
    vpn_type                    = "RouteBased"

    ip_configuration             {
        subnet_id               = azurerm_subnet.vpn.id
        public_ip_address_id    = azurerm_public_ip.vpn.id
    }

    vpn_client_configuration     {
        address_space           = [local.vpn_address_space]
        vpn_client_protocols    = ["IkeV2"]
        root_certificate         {
            name = local.vpn_root_cert_name
            public_cert_data = join("\n",slice(split("\n", file("${path.module}/scripts/P2SVPNRootCert.cer")), 1, length(split("\n",file("${path.module}/scripts/P2SVPNRootCert.cer")))-2))
        }
    }


    
}