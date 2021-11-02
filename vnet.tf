# Author: Alejandro Galue <agalue@opennms.org>

resource "azurerm_resource_group" "main" {
  count    = var.resource_group_create ? 1 : 0
  name     = var.resource_group
  location = var.location
  tags     = local.required_tags
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = local.resource_group
  address_space       = [var.address_space]
  tags                = local.required_tags
}

resource "azurerm_subnet" "main" {
  name                 = "main"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet]

  enforce_private_link_endpoint_network_policies = true
}
