# ===== BOOTSTRAP VARIABLES =====
# These create the backend storage account for Terraform state

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "backend_resource_group_name" {
  description = "Resource group for backend storage"
  type        = string
  default     = "rg-terraform-state"
}

variable "backend_storage_account_name" {
  description = "Storage account name for state files (must be globally unique)"
  type        = string
  # Default will be set in tfvars with a unique name like tfstate<random>
}

variable "backend_region" {
  description = "Region for backend storage"
  type        = string
  default     = "uksouth"
}

variable "dev_container_name" {
  description = "Storage container name for dev state"
  type        = string
  default     = "tfstate-dev"
}

variable "prod_container_name" {
  description = "Storage container name for prod state"
  type        = string
  default     = "tfstate-prod"
}

variable "tags" {
  description = "Tags for backend resources"
  type        = map(string)
  default = {
    terraform = "true"
    purpose   = "terraform-backend"
    managed   = "bootstrap"
  }
}
