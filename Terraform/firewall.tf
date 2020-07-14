resource "azurerm_public_ip" "firewall" {
  name                = local.firewall_publicip
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
  name                = local.firewall_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  ip_configuration {
    name                 = local.firewall_ipconfig_name
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_firewall_application_rule_collection" "aks" {
  name                = local.firewall_aks_application_rule_collection
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.hub.name
  priority            = 300
  action              = "Allow"

  rule {
    name = local.firewall_aks_application_rule

    source_addresses = [
      "*",
    ]

    target_fqdns = [
        "aksrepos.azurecr.io",
        "*blob.core.windows.net",
        "mcr.microsoft.com",
        "*cdn.mscr.io",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "ntp.ubuntu.com",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }
}

resource "azurerm_firewall_application_rule_collection" "docker" {
  name                = local.firewall_docker_application_rule_collection
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.hub.name
  priority            = 400
  action              = "Allow"

  rule {
    name = local.firewall_docker_application_rule

    source_addresses = [
      "*",
    ]

    target_fqdns = [
        "docker.io",
        "quay.io",
        "*.docker.io",
        "*.docker.com",
        "*.quay.io"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }
}