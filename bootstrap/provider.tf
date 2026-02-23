# ===== BOOTSTRAP TERRAFORM - NOT MANAGED BY MODULES =====
# This Terraform code creates the BACKEND (remote state storage)
# It's separate from main infrastructure because:
# 1. It needs to run FIRST (creates storage for other state files)
# 2. It uses local state (not remote, since backend doesn't exist yet)
# 3. It's a one-time setup, rarely changes

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Bootstrap uses local state (no remote backend yet)
  # This is the only time we use local state
}

provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }

  skip_provider_registration = false
}
