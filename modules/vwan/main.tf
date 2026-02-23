# ===== VWAN MODULE - PLACEHOLDER =====
# This module will be completed in Module 4 (Migrate to Azure VWAN)
# For now, basic structure

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vwan_name" {
  description = "Name for VWAN"
  type        = string
  default     = "vwan-hub"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

output "vwan_placeholder" {
  value = "VWAN module will be implemented in Module 4"
}
