# ===== SPOKE MODULE =====
# Reusable module for creating a spoke Virtual Network
#
# SPOKE = satellite VNet connected to hub
# Spokes communicate through the hub (hub-and-spoke topology)
#
# This module creates:
# - Virtual Network (VNet) for the spoke
# - Subnets inside the spoke VNet

variable "resource_group_name" {
  description = "Name of resource group where spoke will be created"
  type        = string
}

variable "location" {
  description = "Azure region for spoke resources"
  type        = string
}

variable "spoke_name" {
  description = "Name for the spoke VNet"
  type        = string
}

variable "spoke_address_space" {
  description = "Address space for spoke VNet (CIDR, e.g., 10.1.0.0/16)"
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create in spoke VNet"
  type = map(object({
    address_prefix = string
    description    = optional(string)
  }))
  default = {
    "workload" = {
      address_prefix = "10.1.0.0/24"
      description    = "Workload subnet"
    }
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ===== DATA SOURCE =====

data "azurerm_resource_group" "spoke" {
  name = var.resource_group_name
}

# ===== SPOKE VNET =====

resource "azurerm_virtual_network" "spoke" {
  name                = var.spoke_name
  address_space       = [var.spoke_address_space]
  location            = data.azurerm_resource_group.spoke.location
  resource_group_name = data.azurerm_resource_group.spoke.name

  tags = merge(
    var.tags,
    {
      type = "spoke"
    }
  )
}

# ===== SUBNETS =====

resource "azurerm_subnet" "spoke_subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = data.azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [each.value.address_prefix]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ServiceBus",
    "Microsoft.EventHub",
  ]
}

# ===== OUTPUTS =====

output "spoke_vnet_id" {
  description = "ID of spoke VNet"
  value       = azurerm_virtual_network.spoke.id
}

output "spoke_vnet_name" {
  description = "Name of spoke VNet"
  value       = azurerm_virtual_network.spoke.name
}

output "spoke_vnet_address_space" {
  description = "Address space of spoke VNet"
  value       = azurerm_virtual_network.spoke.address_space
}

output "spoke_subnet_ids" {
  description = "IDs of all subnets in spoke"
  value = {
    for k, subnet in azurerm_subnet.spoke_subnets : k => subnet.id
  }
}

output "spoke_subnet_names" {
  description = "Names of all subnets in spoke"
  value = {
    for k, subnet in azurerm_subnet.spoke_subnets : k => subnet.name
  }
}
