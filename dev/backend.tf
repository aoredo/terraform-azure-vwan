# ===== MODULE 2: REMOTE STATE BACKEND =====
# In Module 1, we used local state (terraform.tfstate in the dev/ folder)
# Starting in Module 2, we move to remote state in Azure Storage
#
# WHY remote state?
# 1. Team access: Multiple people work on same infrastructure
# 2. Locking: Prevents two people applying at the same time
# 3. Safety: Automatic backups by Azure
# 4. CI/CD: GitHub Actions can access state from cloud
#
# HOW: Store state in Azure Storage Account (created by bootstrap)

terraform {
  backend "azurerm" {
    # These values MUST match what bootstrap created
    # Get these from bootstrap outputs after running bootstrap
    
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatetdops2026"
    container_name       = "tfstate-dev"
    key                  = "terraform.tfstate"
    
    # Authentication: Uses environment variables (set by az login)
    # No username/password stored in code (secure!)
  }
}

# ===== HOW TO MIGRATE FROM LOCAL TO REMOTE STATE =====
#
# Step 1: Ensure bootstrap has created the storage account
#   cd ../bootstrap
#   terraform init
#   terraform apply  (creates rg-terraform-state and storage account)
#
# Step 2: Run terraform init in dev/ to migrate state
#   cd ../dev
#   terraform init
#   (Terraform will ask: "Do you want to copy existing state to new backend?")
#   (Answer: yes)
#
# Step 3: Verify state is in Azure
#   Go to Azure Portal
#   Search for storage account: tfstatetdops2026
#   Navigate to \u2192 Containers \u2192 tfstate-dev
#   Should see terraform.tfstate file there (state migrated!)
#
# Step 4: Delete local state file (optional but recommended)
#   rm -f terraform.tfstate
#   rm -f terraform.tfstate.backup
#   (Local state no longer needed since it's in Azure)
#
# ===== BENEFITS NOW =====
#
# 1. Next person (or GitHub Actions) runs: terraform init, terraform plan
#    They automatically use same state from Azure (not local)
#
# 2. Safe: If local machine crashes, state is safely in Azure
#
# 3. Locking: If you run terraform apply, Azure locks state for ~10 min
#    If someone else runs terraform apply at same time:
#    Error: Resource was locked for X minutes by user@machine
#    (Prevents concurrent modifications that corrupt state)
