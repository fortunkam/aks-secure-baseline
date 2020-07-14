resource "random_password" "sql_password" {
  keepers = {
    resource_group = azurerm_resource_group.spoke.name
  }
  length = 16
  special = true
  override_special = "_%@"
}

resource "azurerm_sql_server" "sql" {
  name                         = local.sql_server_name
  resource_group_name          = azurerm_resource_group.spoke.name
  location                     = azurerm_resource_group.spoke.location
  administrator_login          = var.sqlUsername
  administrator_login_password = random_password.sql_password.result
  version                      = "12.0"
}


resource "azurerm_sql_database" "mydrivingDB" {
  name                = local.mydrivingdb_name
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  server_name         = azurerm_sql_server.sql.name
}

resource "azurerm_key_vault_secret" "sqluser" {
  name         = "SQLUSER"
  value        = var.sqlUsername
  key_vault_id = azurerm_key_vault.aks_keyvault.id
}

resource "azurerm_key_vault_secret" "sqlpassword" {
  name         = "SQLPASSWORD"
  value        = random_password.sql_password.result
  key_vault_id = azurerm_key_vault.aks_keyvault.id
}

resource "azurerm_key_vault_secret" "sqlserver" {
  name         = "SQLSERVER"
  value        = azurerm_sql_server.sql.fully_qualified_domain_name
  key_vault_id = azurerm_key_vault.aks_keyvault.id
}

resource "azurerm_key_vault_secret" "sqldatabase" {
  name         = "SQLDATABASE"
  value        = local.mydrivingdb_name
  key_vault_id = azurerm_key_vault.aks_keyvault.id
}

resource "azurerm_sql_virtual_network_rule" "allow_aks" {
  name                = local.sql_firewall_allow_aks_subnet
  resource_group_name = azurerm_resource_group.spoke.name
  server_name         = azurerm_sql_server.sql.name
  subnet_id           = azurerm_subnet.aks.id
}

resource "azurerm_sql_virtual_network_rule" "allow_vpn" {
  name                = local.sql_firewall_allow_vpn_subnet
  resource_group_name = azurerm_resource_group.spoke.name
  server_name         = azurerm_sql_server.sql.name
  subnet_id           = azurerm_subnet.vpn.id
}

resource "azurerm_sql_virtual_network_rule" "allow_bastion" {
  name                = local.sql_firewall_allow_bastion_subnet
  resource_group_name = azurerm_resource_group.spoke.name
  server_name         = azurerm_sql_server.sql.name
  subnet_id           = azurerm_subnet.bastion.id
}

