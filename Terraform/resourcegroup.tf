resource "azurerm_resource_group" "hub" {
    name     = local.rg_hub_name
    location = var.location
}

resource "azurerm_resource_group" "spoke" {
    name     = local.rg_spoke_name
    location = var.location
}