# ===== FIREWALL MODULE - PLACEHOLDER =====
# This module will be completed in Module 3 (Hub-Spoke with Firewall)
# For now, basic structure to show where firewall configuration goes

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "firewall_name" {
  description = "Name for the firewall"
  type        = string
  default     = "fw-hub"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Placeholder output
output "firewall_placeholder" {
  value = "Firewall module will be implemented in Module 3"
}
