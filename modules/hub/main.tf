# ===== HUB MODULE =====
# Reusable module for creating a hub Virtual Network
# 
# MODULE = collection of Terraform code that can be used in multiple places
# Benefits:
# 1. DRY (Don't Repeat Yourself) - write code once, use multiple times
# 2. Consistency - same configuration pattern everywhere
# 3. Easy updates - change code in one place, affects all uses
#
# This module creates:
# - Resource Group (optional - can be created outside module)
# - Virtual Network (VNet)
# - Subnets inside the VNet

# ===== INPUT VARIABLES =====
# Variables that callers provide when using this module

variable "resource_group_name" {
  description = "Name of resource group where hub will be created"
  type        = string
}

variable "location" {
  description = "Azure region for hub resources"
  type        = string
}

variable "hub_name" {
  description = "Name for the hub VNet"
  type        = string
}

variable "hub_address_space" {
  description = "Address space for hub VNet (CIDR, e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "Map of subnets to create in hub VNet"
  type = map(object({
    address_prefix = string
    description    = optional(string)
  }))
  default = {
    "management" = {
      address_prefix = "10.0.1.0/24"
      description    = "Management subnet"
    }
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ===== DATA SOURCE =====
# Get reference to existing resource group
# (caller might create it, or it might already exist)

data "azurerm_resource_group" "hub" {
  name = var.resource_group_name
}

# ===== HUB VNET RESOURCE =====

resource "azurerm_virtual_network" "hub" {
  name                = var.hub_name
  address_space       = [var.hub_address_space]
  location            = data.azurerm_resource_group.hub.location
  resource_group_name = data.azurerm_resource_group.hub.name

  tags = merge(
    var.tags,
    {
      type = "hub"
    }
  )
}

# ===== SUBNETS =====
# Create multiple subnets based on input variable
# for_each = loop through each subnet definition

resource "azurerm_subnet" "hub_subnets" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = data.azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value.address_prefix]

  # Service endpoints - let specified services access this subnet securely
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ServiceBus",
    "Microsoft.EventHub",
  ]
}

# ===== OUTPUTS =====
# Return important values for caller to use

output "hub_vnet_id" {
  description = "ID of hub VNet"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of hub VNet"
  value       = azurerm_virtual_network.hub.name
}

output "hub_vnet_address_space" {
  description = "Address space of hub VNet"
  value       = azurerm_virtual_network.hub.address_space
}

output "hub_subnet_ids" {
  description = "IDs of all subnets in hub"
  value = {
    for k, subnet in azurerm_subnet.hub_subnets : k => subnet.id
  }
}

output "hub_subnet_names" {
  description = "Names of all subnets in hub"
  value = {
    for k, subnet in azurerm_subnet.hub_subnets : k => subnet.name
  }
}

output "hub_resource_group_name" {
  description = "Resource group containing hub"
  value       = data.azurerm_resource_group.hub.name
}
