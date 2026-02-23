# ===== BOOTSTRAP OUTPUTS =====
# These outputs show the storage account details needed to configure dev/backend.tf

output "backend_resource_group_name" {
  description = "Resource group name for backend"
  value       = azurerm_resource_group.backend.name
}

output "backend_storage_account_name" {
  description = "Storage account name (use in dev/backend.tf)"
  value       = azurerm_storage_account.backend.name
}

output "dev_container_name" {
  description = "Dev state container name (use in dev/backend.tf)"
  value       = azurerm_storage_container.dev_state.name
}

output "prod_container_name" {
  description = "Prod state container name (use in prod/backend.tf)"
  value       = azurerm_storage_container.prod_state.name
}

output "backend_storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.backend.id
}

output "backend_access_key" {
  description = "Primary access key for storage account (keep secure!)"
  value       = azurerm_storage_account.backend.primary_access_key
  sensitive   = true
}
