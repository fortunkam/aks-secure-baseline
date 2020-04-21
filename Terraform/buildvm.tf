resource "tls_private_key" "build" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "build" {
  name                = local.build_agent_internal_nic
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.buildagent.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "build" {
  name                = local.build_agent_vm
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.build.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.build.public_key_openssh
  }

  os_disk {
      name              = local.build_agent_disk
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

resource "azurerm_role_assignment" "buildacrpush" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_linux_virtual_machine.build.identity[0].principal_id
}

resource "azurerm_virtual_machine_extension" "installbuildservers" {
  name                 = "installbuildtools"
  virtual_machine_id   = azurerm_linux_virtual_machine.build.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  protected_settings = <<PROTECTED_SETTINGS
    {
        "fileUris": [
            "${azurerm_storage_blob.installbuildserver.url}${data.azurerm_storage_account_blob_container_sas.scripts.sas}"
        ],
        "commandToExecute": "bash InstallBuildServer.sh -u ${var.devopsUrl} -t ${var.devopsPatToken} -p ${var.devopsBuildAgentPool} -a ${azurerm_linux_virtual_machine.build.name}"
    }
PROTECTED_SETTINGS
    depends_on = [azurerm_storage_blob.installbuildserver]

    lifecycle {
        ignore_changes = all
    }
}