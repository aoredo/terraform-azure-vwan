# ===== MODULE 2: REFACTORED OUTPUTS =====
# Now outputs reference the module outputs instead of direct resource outputs

output "hub_resource_group_name" {
  description = "Name of the hub resource group"
  value       = azurerm_resource_group.hub.name
}

output "hub_resource_group_id" {
  description = "ID of the hub resource group"
  value       = azurerm_resource_group.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub VNet (from module)"
  value       = module.hub_network.hub_vnet_name
}

output "hub_vnet_id" {
  description = "ID of the hub VNet (from module)"
  value       = module.hub_network.hub_vnet_id
}

output "hub_vnet_address_space" {
  description = "Address space of the hub VNet (from module)"
  value       = module.hub_network.hub_vnet_address_space
}

output "hub_subnet_ids" {
  description = "IDs of all subnets in hub (from module)"
  value       = module.hub_network.hub_subnet_ids
}

output "hub_subnet_names" {
  description = "Names of all subnets in hub (from module)"
  value       = module.hub_network.hub_subnet_names
}
