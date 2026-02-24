# ===== MODULE 2: REFACTORED MAIN.TF USING MODULES =====
# Now instead of defining resources here, we use modules
# 
# BEFORE (Module 1): 
#   resource "azurerm_resource_group" {...}
#   resource "azurerm_virtual_network" {...}
#   resource "azurerm_subnet" {...}
#
# AFTER (Module 2):
#   module "hub" {
#     ...
#   }
#
# Benefits:
# - Code is cleaner and easier to read
# - Hub configuration defined once (in modules/hub/), used everywhere
# - Easy to reuse: add 5 spokes with just 5 module calls
# - Easier to maintain: change hub config in one place affects all

# ===== CREATE RESOURCE GROUP =====
# First, create the resource group (container for all resources)

resource "azurerm_resource_group" "hub" {
  name       = var.resource_group_name
  location   = var.region
  
  tags = merge(
    var.tags,
    {
      name = "rg-hub"
    }
  )
}

# ===== USE HUB MODULE =====
# Call the hub module to create VNet and subnets

module "hub_network" {
  source = "../modules/hub"

  # Pass variables to module
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.region
  hub_name            = var.hub_vnet_name
  hub_address_space   = var.hub_vnet_address_space

  # Configure subnets inside hub
  subnets = {
    (var.hub_subnet_name) = {
      address_prefix = var.hub_subnet_address_prefix
      description    = "Hub management subnet"
    }
  }

  tags = var.tags

  # Explicit dependency - ensure RG created first
  depends_on = [azurerm_resource_group.hub]
}

module "spoke1" {
    source = "../modules/spoke"
    
    resource_group_name = azurerm_resource_group.hub.name
    location            = var.region
    spoke_name          = "vnet-spoke-1"
    spoke_address_space = "10.1.0.0/16"

    subnets = {
      "workload" = {
        address_prefix = "10.1.1.0/24" 
        description    = "spoke 1"
      }
    }
    tags = var.tags

    depends_on = [azurerm_resource_group.hub]   

}



# ===== HOW TO USE THIS =====
#
# To reference outputs from a module:
#   module.HUB_MODULE_NAME.OUTPUT_NAME
#
# In this case:
#   module.hub_network.hub_vnet_id       → ID of the hub VNet
#   module.hub_network.hub_vnet_name     → Name of the hub VNet
#   module.hub_network.hub_subnet_ids    → IDs of all subnets
#
# All of these are defined in modules/hub/main.tf (output section)
#
# Example use in Module 3:
#   We'll use module.hub_network.hub_vnet_id to attach a firewall to hub VNet
