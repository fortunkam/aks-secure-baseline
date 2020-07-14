resource "azurerm_log_analytics_workspace" "loganalytics" {
  name                = local.loganalytics_workspace_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}