# Author: Alejandro Galue <agalue@opennms.org>

locals {
  onms_vm = "${var.name_prefix}-onms"
}

resource "azurerm_network_security_group" "opennms" {
  name                = "${local.onms_vm}-sg"
  location            = var.location
  resource_group_name = local.resource_group
  tags                = local.required_tags

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Ingress"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "LetsEncrypt"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "opennms" {
  name                = "${local.onms_vm}-public-ip"
  location            = var.location
  resource_group_name = local.resource_group
  tags                = local.required_tags
  domain_name_label   = local.onms_vm
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "opennms" {
  name                = "${local.onms_vm}-nic"
  location            = var.location
  resource_group_name = local.resource_group
  tags                = local.required_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    public_ip_address_id          = azurerm_public_ip.opennms.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "opennms" {
  network_interface_id      = azurerm_network_interface.opennms.id
  network_security_group_id = azurerm_network_security_group.opennms.id
}

data "template_file" "opennms" {
  template = file("opennms.yaml.tpl")
  vars     = {
    user         = var.user
    email        = var.email
    location     = var.location
    onms_fqdn    = "${local.onms_vm}.${var.location}.cloudapp.azure.com"
    eh_bootstrap = "${azurerm_eventhub_namespace.opennms.name}.servicebus.windows.net:9093"
    eh_connstr   = azurerm_eventhub_namespace.opennms.default_primary_connection_string
    pg_local     = var.pg_local
    # If pg_local is true, the rest is ignored (for testing purposes)
    pg_ipaddr    = azurerm_private_endpoint.postgres.private_service_connection[0].private_ip_address
    pg_user      = "postgres@${azurerm_postgresql_server.opennms.name}"
    pg_passwd    = var.pg_passwd
  }
}

data "template_cloudinit_config" "opennms" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.opennms.rendered
  }
}

resource "azurerm_linux_virtual_machine" "opennms" {
  name                  = local.onms_vm
  resource_group_name   = local.resource_group
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.user
  custom_data           = data.template_cloudinit_config.opennms.rendered
  network_interface_ids = [ azurerm_network_interface.opennms.id ]
  tags                  = local.required_tags

  admin_ssh_key {
    username   = var.user
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = var.os_image.publisher
    offer     = var.os_image.offer
    sku       = var.os_image.sku
    version   = var.os_image.version
  }

  os_disk {
    name                 = "${local.onms_vm}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
