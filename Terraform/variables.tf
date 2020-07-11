variable location {
    default="uksouth"
}
variable prefix {
    default="mfaks"
}

variable devopsUrl {
}

variable devopsPatToken {
}

variable devopsBuildAgentPool {
}

variable devopsDeployAgentPool {
}


locals {
    rg_hub_name = "${var.prefix}-hub-rg"
    rg_spoke_name = "${var.prefix}-spoke-rg"
    vnet_hub_name="${var.prefix}-hub-vnet"
    vnet_spoke_name="${var.prefix}-spoke-vnet"
    vnet_hub_iprange="10.0.0.0/16"
    vnet_spoke_iprange="10.1.0.0/16"
    firewall_subnet="AzureFirewallSubnet"
    firewall_subnet_iprange="10.0.0.0/24"
    buildagent_subnet="buildagents"
    buildagent_subnet_iprange="10.0.1.0/24"
    deployagent_subnet="deployagents"
    deployagent_subnet_iprange="10.0.3.0/24"
    bastion_subnet="bastion"
    bastion_subnet_iprange="10.0.2.0/24"
    acr_subnet="acr"
    acr_subnet_iprange="10.1.0.0/24"
    aks_subnet="aks"
    aks_subnet_iprange="10.1.1.0/24"
    hub_to_spoke_vnet_peer="${var.prefix}-hub-spoke-peer"
    spoke_to_hub_vnet_peer="${var.prefix}-spoke-hub-peer"
    firewall_publicip="${var.prefix}-fw-ip"
    firewall_name="${var.prefix}-fw"
    firewall_route_table_name="${var.prefix}fwrt"
    firewall_route_name="${var.prefix}fwrn"
    firewall_route_internet_name="${var.prefix}fwinternet"
    firewall_ipconfig_name="${var.prefix}fwconfig"
    firewall_aks_application_rule_collection="aks_rule_collection"
    firewall_aks_application_rule="aks_rule"
    bastion_publicip="${var.prefix}-bastion-ip"
    bastion_vm="${var.prefix}-bs-vm"
    bastion_disk="${var.prefix}-bastion-disk"
    bastion_nsg="${var.prefix}-bastion-nsg"
    bastion_internal_ipconfig="${var.prefix}-bastion-in-config"
    bastion_internal_nic="${var.prefix}-bastion-in-nic"
    bastion_external_nic="${var.prefix}-bastion-ext-nic"
    bastion_external_ipconfig="${var.prefix}-bastion-ext-config"
    key_vault_name="${var.prefix}kv"
    acr_dns_zone="privatelink.azurecr.io"
    acr_private_link="${var.prefix}-private-link"
    acr_private_endpoint="${var.prefix}-storage-private-endpoint"
    acr_dns_link_spoke="${var.prefix}-storage-dns-spoke-link"
    acr_dns_link_hub="${var.prefix}-storage-dns-hub-link"
    acr_name="${var.prefix}acr"
    bastion_username="AzureAdmin"
    bastion_server_private_ip="10.0.2.128"
    aks_name="${var.prefix}-aks"
    storage_deploy="${var.prefix}deploy"
    storage_deploy_container_name="scripts"
    build_agent_linux_url="https://vstsagentpackage.azureedge.net/agent/2.166.2/vsts-agent-linux-x64-2.166.2.tar.gz"
    build_agent_vm="${var.prefix}-bld-vm"
    build_agent_disk="${var.prefix}-bld-disk"
    build_agent_internal_nic="${var.prefix}-bld-in-nic"

    deploy_agent_vm="${var.prefix}-dpy-vm"
    deploy_agent_disk="${var.prefix}-dpy-disk"
    deploy_agent_internal_nic="${var.prefix}-dpy-in-nic"

}

data "azurerm_client_config" "current" {
}
data "azurerm_subscription" "primary" {
}

resource "random_password" "bastion_password" {
  keepers = {
    resource_group = azurerm_resource_group.hub.name
  }
  length = 16
  special = true
  override_special = "_%@"
}
