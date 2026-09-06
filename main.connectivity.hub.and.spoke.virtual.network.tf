module "hub_and_spoke_vnet" {
  source = "./modules/contoso-connectivity"

  count = local.connectivity_hub_and_spoke_vnet_enabled ? 1 : 0

  hub_and_spoke_networks_settings = local.hub_and_spoke_networks_settings
  hub_virtual_networks            = local.hub_virtual_networks
  enable_telemetry                = var.enable_telemetry
  tags                            = coalesce(module.config.outputs.connectivity_tags, module.config.outputs.tags)
  required_public_ip_tags = {
    FirstPartyUsage = "/Unprivileged"
  }
  subnet_network_security_group_ids = {
    for key, hub in local.hub_virtual_networks : key => {
      bastion      = "${hub.default_parent_id}/providers/Microsoft.Network/networkSecurityGroups/${hub.hub_virtual_network.name}-AzureBastionSubnet-nsg-${hub.location}"
      dns_resolver = "${hub.default_parent_id}/providers/Microsoft.Network/networkSecurityGroups/${hub.hub_virtual_network.name}-dns-resolver-nsg-${hub.location}"
    } if contains(["primary", "secondary"], key)
  }

  providers = {
    azurerm = azurerm.connectivity
    azapi   = azapi.connectivity
  }
}
