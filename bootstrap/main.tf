# ===== RESOURCE GROUP FOR BACKEND =====
resource "azurerm_resource_group" "backend" {
  name       = var.backend_resource_group_name
  location   = var.backend_region
  
  tags = merge(
    var.tags,
    {
      name = "Backend Resource Group"
    }
  )
}

# ===== STORAGE ACCOUNT FOR STATE FILES =====
# Storage Account = Azure's file storage (like S3 in AWS)
# We use it to store Terraform state files remotely
#
# WHY remote state?
# 1. Team access: Multiple people can access same state
# 2. Safety: Azure manages backups automatically
# 3. Locking: Prevents concurrent modifications (two people applying at same time)
# 4. Versioning: Track state changes over time

resource "azurerm_storage_account" "backend" {
  name                     = var.backend_storage_account_name
  resource_group_name      = azurerm_resource_group.backend.name
  location                 = var.backend_region
  account_tier             = "Standard"
  account_replication_type = "LRS"  # Locally Redundant Storage = replicated within one region
  
  # Security settings
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  tags = merge(
    var.tags,
    {
      name = "Terraform State Storage"
    }
  )
}

# ===== STORAGE CONTAINERS =====
# Container = folder inside storage account
# We create separate containers for dev and prod state files

resource "azurerm_storage_container" "dev_state" {
  name                  = var.dev_container_name
  storage_account_name  = azurerm_storage_account.backend.name
  container_access_type = "private"
  # private = only authenticated users can access (secure)
}

resource "azurerm_storage_container" "prod_state" {
  name                  = var.prod_container_name
  storage_account_name  = azurerm_storage_account.backend.name
  container_access_type = "private"
}

# ===== STORAGE ACCOUNT KEYS =====
# Azure Storage requires access keys for connections
# We'll use these later in dev/backend.tf and prod/backend.tf

data "azurerm_storage_account_blob_container_sas" "dev" {
  connection_string = azurerm_storage_account.backend.primary_blob_connection_string
  container_name    = azurerm_storage_container.dev_state.name
  https_only        = true

  start  = "2024-01-01"
  expiry = "2099-12-31"

  permissions {
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
  }
}
