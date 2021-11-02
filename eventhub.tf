# Author: Alejandro Galue <agalue@opennms.org>

resource "azurerm_eventhub_namespace" "opennms" {
  name                = "${var.name_prefix}-onms"
  location            = var.location
  resource_group_name = local.resource_group
  sku                 = "Standard"
  capacity            = 1
  tags                = local.required_tags
}

resource "azurerm_eventhub" "opennms" {
  name                = "${var.name_prefix}-onms"
  namespace_name      = azurerm_eventhub_namespace.opennms.name
  resource_group_name = local.resource_group
  partition_count     = 2
  message_retention   = 1
}