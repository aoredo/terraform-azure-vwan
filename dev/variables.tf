# ===== TERRAFORM VARIABLES =====
# Variables are like placeholders/inputs for your configuration
# Instead of hardcoding values, define them here, then reference them in main.tf
#
# WHY? Makes code reusable and easy to change without editing main.tf
# Example: Change subscription ID in one place (terraform.tfvars), not everywhere
#
# Variable values come from terraform.tfvars file (see that file for actual values)

variable "azure_subscription_id" {
  description = "Azure Subscription ID where resources will be created"
  type        = string
  # No default value - user MUST provide this in terraform.tfvars
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID (used for authentication)"
  type        = string
  # No default value - user MUST provide this
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  # Default value = if not specified, uses 'dev'
}

variable "region" {
  description = "Azure region where resources will be deployed (e.g., eastus, westus)"
  type        = string
  default     = "eastus"
  # Can be overridden in terraform.tfvars
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-terraform-lab"
  # Resource Group = container that holds all your Azure resources
}

variable "hub_vnet_name" {
  description = "Name of the hub Virtual Network (VNet)"
  type        = string
  default     = "vnet-hub-primary"
}

variable "hub_vnet_address_space" {
  description = "Address space for hub VNet (CIDR notation, e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
  # 10.0.0.0/16 = network with 65,536 IP addresses (10.0.0.0 through 10.0.255.255)
}

variable "hub_subnet_name" {
  description = "Name of the subnet inside hub VNet"
  type        = string
  default     = "subnet-hub-management"
}

variable "hub_subnet_address_prefix" {
  description = "Address prefix for hub subnet (e.g., 10.0.1.0/24)"
  type        = string
  default     = "10.0.1.0/24"
  # 10.0.1.0/24 = 256 IP addresses (10.0.1.0 through 10.0.1.255)
}

variable "tags" {
  description = "Tags to apply to all resources (for organization and cost tracking)"
  type        = map(string)
  default = {
    terraform   = "true"
    environment = "dev"
    module      = "module-1-foundations"
    purpose     = "learning-lab"
  }
  # Tags are like labels - help you find and organize resources in Azure portal
}

# ===== BEST PRACTICE =====
# 1. Always use variables for values that might change
# 2. Set defaults for flexibility, but require important values (no defaults)
# 3. Use descriptive names and clear descriptions
# 4. Group related variables together
