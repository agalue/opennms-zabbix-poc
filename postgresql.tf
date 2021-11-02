# Author: Alejandro Galue <agalue@opennms.org>

resource "azurerm_postgresql_server" "opennms" {
  name                = "${var.name_prefix}-pg"
  location            = var.location
  resource_group_name = local.resource_group
  tags                = local.required_tags

  administrator_login          = "postgres"
  administrator_login_password = var.pg_passwd

  sku_name   = "GP_Gen5_4"
  version    = "11"
  storage_mb = 640000

  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  auto_grow_enabled             = false
  public_network_access_enabled = false
  ssl_enforcement_enabled       = false
}

resource "azurerm_private_endpoint" "postgres" {
  name                = "${var.name_prefix}-pgpe"
  location            = var.location
  resource_group_name = local.resource_group
  subnet_id           = azurerm_subnet.main.id
  tags                = local.required_tags

  private_service_connection {
    name                           = "onms-postgresql-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_postgresql_server.opennms.id
    subresource_names              = ["postgresqlServer"]
  }
}