# Author: Alejandro Galue <agalue@opennms.org>

variable "email" {
  description = "Email address to use with LetsEncrypt for TLS; used only when security.enabled=true"
  type        = string
}

variable "user" {
  description = "The user to access VMs and name prefix for Azure resources."
  type        = string
  default     = "agalue"
}

variable "name_prefix" {
  description = "A prefix to add to all Azure resources, to make them unique."
  type        = string
  default     = "qa-env1"
}

variable "resource_group_create" {
  description = "Set to true to create the resource group."
  type        = bool
  default     = false
}

variable "resource_group" {
  description = "The name of the Azure Resource Group."
  type        = string
  default     = "support-testing"
}

variable "location" {
  description = "The name of the Azure Location."
  type        = string
  default     = "eastus"
}


variable "address_space" {
  description = "The Virtual Network Address Space."
  type        = string
  default     = "14.0.0.0/16"
}

# The subnet CIDR must exist within the address_space of the chosen virtual network.
variable "subnet" {
  description = "The subnet range for the chosen Address Space."
  type        = string
  default     = "14.0.1.0/24"
}

variable "vm_size" {
  description = "The size of the OpenNMS VM."
  type        = string
  default     = "Standard_D8s_v4" #  8 Cores and 32 GB of RAM
}

variable "pg_passwd" {
  description = "Password for the postgres user."
  type        = string
  default     = "Psql0p3nNM5;"
}

variable "pg_local" {
  description = "Use local PostgreSQL (for testing purposes)."
  type        = bool
  default     = true
}

# Must be consistent with the chosen Location/Region
variable "os_image" {
  description = "The OS Image to use for OpenNMS."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_4"
    version   = "latest"
  }
}

locals {
  # To guarantee the existence of the group if it has to be created 
  resource_group = var.resource_group_create ? azurerm_resource_group.main[0].name : var.resource_group
  required_tags = {
    Owner       = "${var.user}"
    Environment = "QA"
    Department  = "Support"
  }
}
