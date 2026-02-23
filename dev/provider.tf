# ===== TERRAFORM CONFIGURATION =====
# This file tells Terraform which cloud provider to use and how to authenticate
# For Azure, we use the azurerm provider (Azure Resource Manager)

terraform {
  # Specify required Terraform version
  required_version = ">= 1.0"

  # Specify required providers and their versions
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Backend configuration will be added in Module 2 (remote state in Azure Storage)
  # For now, state is stored locally in terraform.tfstate
}

# ===== AZURE PROVIDER CONFIGURATION =====
# Configure the Azure provider with OIDC authentication (recommended for CI/CD)
# OIDC = OpenID Connect: secure way to authenticate without storing credentials

provider "azurerm" {
  # Features block for provider-specific behaviors
  features {
    # Prevent accidental deletion of certain resources
    virtual_machine {
      delete_os_disk_on_deletion            = true
      graceful_shutdown                     = false
      skip_shutdown_and_force_delete         = false
    }
  }

  # Authentication method: OIDC (OpenID Connect)
  # When running locally, this will prompt you to authenticate
  # When running in GitHub Actions, the GITHUB_ environment variables handle it automatically
  
  # These variables come from environment variables set in CI/CD or local Azure CLI
  # az login - authenticates locally and sets these environment variables
  
  skip_provider_registration = false
}

# ===== AUTHENTICATION SETUP =====
# BEFORE running terraform:
#
# 1. LOCAL DEVELOPMENT (your machine):
#    - Install: brew install azure-cli (macOS) or get from https://learn.microsoft.com/cli/azure/install-azure-cli
#    - Then run: az login
#    - az cli will open a browser, you log in with your Azure account
#    - After that, Terraform can use those credentials automatically
#
# 2. GITHUB ACTIONS CI/CD (automated pipeline):
#    - Will set up OIDC in Module 5
#    - Terraform will authenticate using GitHub's OIDC tokens (no secrets stored)
