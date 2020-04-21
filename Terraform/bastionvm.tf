resource "azurerm_public_ip" "bastion" {
  name                = local.bastion_publicip
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "bastion" {
  name                = local.bastion_nsg
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
}

resource "azurerm_network_security_rule" "rdp" {
  name                        = "rdp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.hub.name
  network_security_group_name = azurerm_network_security_group.bastion.name
}


resource "azurerm_network_interface" "bastion_internal" {
  name                = local.bastion_internal_nic
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name

  ip_configuration {
    name                          = local.bastion_internal_ipconfig
    subnet_id                     = azurerm_subnet.bastion.id
    private_ip_address_allocation = "Static"
    private_ip_address  = local.bastion_server_private_ip
    public_ip_address_id          = azurerm_public_ip.bastion.id
    primary = true
  }
}

resource "azurerm_network_interface_security_group_association" "bastion" {
  network_interface_id      = azurerm_network_interface.bastion_internal.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_virtual_machine" "bastion" {
  name                  = local.bastion_vm
  location              = azurerm_resource_group.hub.location
  resource_group_name   = azurerm_resource_group.hub.name
  network_interface_ids = [
        azurerm_network_interface.bastion_internal.id
    ]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name              = local.bastion_disk
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = local.bastion_vm
    admin_username = local.bastion_username
    admin_password = random_password.bastion_password.result
  }
  os_profile_windows_config {
      provision_vm_agent        = true
  }

  identity {
      type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "storageblobreader" {
  scope                = azurerm_storage_account.deploy.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_virtual_machine.bastion.identity[0].principal_id
}

resource "azurerm_virtual_machine_extension" "installchocolatey" {
  name                 = "installchocolatey"
  virtual_machine_id   = azurerm_virtual_machine.bastion.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "fileUris": [
            "${azurerm_storage_blob.installchoc.url}${data.azurerm_storage_account_blob_container_sas.scripts.sas}"
        ],
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File InstallChocolateyComponents.ps1"
    }
SETTINGS
    depends_on = [azurerm_storage_blob.installchoc]

    lifecycle {
        ignore_changes = all
    }
}
