resource "azurerm_storage_account" "deploy" {
  name                     = local.storage_deploy
  resource_group_name      = azurerm_resource_group.hub.name
  location                 = azurerm_resource_group.hub.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  identity {
      type = "SystemAssigned"
  }
}

resource "azurerm_storage_container" "scripts" {
  name                  = local.storage_deploy_container_name
  storage_account_name  = azurerm_storage_account.deploy.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "installchoc" {
  name                   = "InstallChocolateyComponents.ps1"
  storage_account_name   = azurerm_storage_account.deploy.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/scripts/InstallChocolateyComponents.ps1"
}

resource "azurerm_storage_blob" "installbuildserver" {
  name                   = "InstallBuildServer.sh"
  storage_account_name   = azurerm_storage_account.deploy.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/scripts/InstallBuildServer.sh"
}

resource "azurerm_storage_blob" "installdeployserver" {
  name                   = "InstallDeployServer.sh"
  storage_account_name   = azurerm_storage_account.deploy.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/scripts/InstallDeployServer.sh"
}

data "azurerm_storage_account_blob_container_sas" "scripts" {
  connection_string = azurerm_storage_account.deploy.primary_connection_string
  container_name    = azurerm_storage_container.scripts.name
  https_only        = true

  start  = "${timestamp()}"
  expiry = "${timeadd(timestamp(), "1h")}"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

