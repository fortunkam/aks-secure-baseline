

resource "azurerm_network_interface" "deploy" {
  name                = local.deploy_agent_internal_nic
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.deployagent.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "deploy" {
  name                = local.deploy_agent_vm
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.deploy.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.build.public_key_openssh
  }

  os_disk {
      name              = local.deploy_agent_disk
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

    identity {
      type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "deployacrpull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_virtual_machine.deploy.identity[0].principal_id
}

resource "azurerm_virtual_machine_extension" "installdeployservers" {
  name                 = "installdeploytools"
  virtual_machine_id   = azurerm_linux_virtual_machine.deploy.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = <<PROTECTED_SETTINGS
    {
        "fileUris": [
            "${azurerm_storage_blob.installdeployserver.url}${data.azurerm_storage_account_blob_container_sas.scripts.sas}"
        ],
        "commandToExecute": "bash InstallDeployServer.sh -u ${var.devopsUrl} -t ${var.devopsPatToken} -p ${var.devopsDeployAgentPool} -a ${azurerm_linux_virtual_machine.deploy.name}"
    }
PROTECTED_SETTINGS
    depends_on = [azurerm_storage_blob.installdeployserver]

    lifecycle {
        ignore_changes = all
    }
}