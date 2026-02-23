# ===== VPN MODULE - PLACEHOLDER =====
# This module will be completed in Module 4 (VPN Gateway & CI/CD)

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vpn_name" {
  description = "Name for VPN gateway"
  type        = string
  default     = "vpngw-hub"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

output "vpn_placeholder" {
  value = "VPN module will be implemented in Module 4"
}
