# Module 1: Terraform Foundations & Azure Auth

## Overview

In this module, you'll learn:
- Terraform syntax and structure
- Azure provider configuration
- How to authenticate with Azure using OIDC
- Deploy your first Azure resources (Resource Group + VNet + Subnet)

**Estimated Time**: 2-3 hours  
**Cost**: ~$0.50/day for resources used  
**Success**: Resource Group and VNet visible in Azure Portal

---

## Step 1: Prerequisites - Install Required Tools

### 1.1 Install Terraform

```bash
# macOS
brew install terraform

# Verify installation
terraform -version
# Should output: Terraform v1.X.X
```

### 1.2 Install Azure CLI

```bash
# macOS
brew install azure-cli

# Verify installation
az version
# Should output version info
```

### 1.3 Install Git (likely already have it)

```bash
git --version
```

---

## Step 2: Authenticate with Azure

### 2.1 Sign in to Azure

```bash
# This opens a browser - sign in with your Azure account
az login

# Output should show:
# [
#   {
#     "cloudName": "AzureCloud",
#     "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",    <- SUBSCRIPTION ID
#     "isDefault": true,
#     "name": "Your Subscription Name",
#     "state": "Enabled",
#     "tenantId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" <- TENANT ID
#   }
# ]
```

### 2.2 Find Your Subscription ID and Tenant ID

```bash
# List all subscriptions
az account list --output table

# Output shows:
# Name                      CloudName    SubscriptionId                        TenantId
# ------------------------  -----------  ------------------------------------  ------------------------------------
# Your Subscription         AzureCloud   12345678-1234-1234-1234-123456789012  87654321-4321-4321-4321-210987654321
```

**COPY these two values** - you'll need them next.

---

## Step 3: Configure Terraform Variables

### 3.1 Edit `dev/terraform.tfvars`

Navigate to the `/dev/terraform.tfvars` file and replace:

```hcl
# Change this:
azure_subscription_id = "REPLACE_WITH_YOUR_SUBSCRIPTION_ID"
azure_tenant_id = "REPLACE_WITH_YOUR_TENANT_ID"

# To this (paste the values you got from az login):
azure_subscription_id = "12345678-1234-1234-1234-123456789012"
azure_tenant_id = "87654321-4321-4321-4321-210987654321"
```

---

## Step 4: Initialize Terraform

Initialize Terraform in the dev directory. This downloads the Azure provider and sets up Terraform.

```bash
cd /Users/aoredope/terraform-azure-vwan/dev

# Initialize Terraform
terraform init

# Output should include:
# ---
# Terraform has been successfully configured!
# ---
```

**What happened:**
- Terraform downloaded the hashicorp/azurerm provider (~3.X version)
- Created `.terraform/` directory (Terraform's workspace - don't edit manually)
- Created `.terraform.lock.hcl` (locks provider versions for reproducibility)

---

## Step 5: Validate Terraform Code

Check that your Terraform code is syntactically correct.

```bash
# Still in /Users/aoredope/terraform-azure-vwan/dev

terraform validate

# Should output:
# Success! The configuration is valid.
```

**What happened:**
- Terraform checked all `.tf` files for syntax errors
- Verified variable definitions and resource types are correct

---

## Step 6: Plan Your Infrastructure

Before applying, see exactly what Terraform will create.

```bash
# Still in /Users/aoredope/terraform-azure-vwan/dev

terraform plan

# Output should show:
# ========================================
# Terraform will perform the following actions:
# 
# + azurerm_resource_group.hub
#     name       = "rg-terraform-lab-dev"
#     location   = "eastus"
#     ...
# 
# + azurerm_virtual_network.hub
#     name                = "vnet-hub-dev"
#     address_space       = ["10.0.0.0/16"]
#     ...
# 
# + azurerm_subnet.hub_management
#     name                 = "subnet-hub-management-dev"
#     address_prefixes     = ["10.0.1.0/24"]
#     ...
# 
# Plan: 3 to add, 0 to change, 0 to destroy
# ========================================
```

**This is crucial**: Review the plan before applying. If anything looks wrong, press `Ctrl+C` to cancel and review your `.tf` files.

---

## Step 7: Apply - Create Resources in Azure

Now actually create the resources in Azure.

```bash
# Still in /Users/aoredope/terraform-azure-vwan/dev

terraform apply

# Terraform will ask for confirmation:
# Do you want to perform these actions?
# Type: yes

# After a few seconds, you should see:
# ========================================
# Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
# 
# Outputs:
# 
# hub_resource_group_id = "/subscriptions/12345.../resourceGroups/rg-terraform-lab-dev"
# hub_resource_group_name = "rg-terraform-lab-dev"
# hub_vnet_id = "/subscriptions/12345.../virtualNetworks/vnet-hub-dev"
# hub_vnet_name = "vnet-hub-dev"
# ...
# ========================================
```

**What happened:**
- Terraform authenticated with Azure using your `az login` credentials
- Created 1 Resource Group
- Created 1 Virtual Network (VNet)
- Created 1 Subnet inside that VNet
- Created `terraform.tfstate` file storing all resource info
- Displayed outputs (resource IDs, names, etc.)

---

## Step 8: Verify in Azure Portal

### 8.1 Go to Azure Portal

```
https://portal.azure.com
```

### 8.2 Find Your Resources

Search for "Resource Groups" in the search bar at the top.

![workflow][1]

1. Search: Type "resource groups"
2. Click: Select "Resource groups" from results
3. Look for: `rg-terraform-lab-dev` (your resource group)
4. Click it to see inside

### 8.3 Explore Your VNet

Inside your Resource Group:
1. Look for resources list on the left side
2. Click "Deployments" to see what Terraform created
3. Click "Virtual Networks" → `vnet-hub-dev`
4. You should see the subnet `subnet-hub-management-dev` inside

**Congratulations!** You've deployed your first infrastructure with Terraform!

---

## Step 9: Understand Terraform State

### 9.1 Inspect Local State

```bash
# Still in /Users/aoredope/terraform-azure-vwan/dev

# List all resources Terraform is tracking
terraform state list

# Output:
# azurerm_resource_group.hub
# azurerm_subnet.hub_management
# azurerm_virtual_network.hub
```

### 9.2 See Details of a Resource

```bash
# Show detailed info about the VNet
terraform state show azurerm_virtual_network.hub

# Output shows IDs, properties, tags, everything Terraform knows about this resource
```

**This is state**: Terraform tracks every resource and its properties in the state file.

---

## Step 10: Clean Up & Save Resources

### Option A: Destroy Resources (if you're done for the day)

To not be charged for idle resources:

```bash
# Still in /Users/aoredope/terraform-azure-vwan/dev

terraform destroy

# Terraform will ask:
# Do you really want to destroy?
# Type: yes

# Output:
# ========================================
# Destroy complete! Resources: 3 destroyed.
# ========================================
```

**What happened:**
- All resources deleted from Azure
- `terraform.tfstate` is updated to reflect destroyed state
- You can always run `terraform apply` again to recreate them

### Option B: Keep Resources Running

If you want to keep them for the next module:

```bash
# Just stop here - resources stay running in Azure
# You'll pay for them until you destroy
```

---

## Module 1 Success Checklist

✅ Terraform installed and version `>= 1.0`  
✅ Azure CLI installed  
✅ Successfully ran `az login`  
✅ Copied Subscription ID and Tenant ID to `terraform.tfvars`  
✅ Ran `terraform init` without errors  
✅ Ran `terraform validate` - success  
✅ Ran `terraform plan` - shows 3 resources to create  
✅ Ran `terraform apply` - resources deployed  
✅ Saw resources in Azure Portal  
✅ Ran `terraform destroy` - resources cleaned up  

---

## Troubleshooting

### Error: "invalid session token"

```
Error getting subscription
```

**Solution**: Re-authenticate with Azure:

```bash
az logout
az login
```

### Error: "invalid subscription id"

```
InvalidSubscriptionId: The subscription is not valid
```

**Solution**: Check `terraform.tfvars` - make sure subscription ID is correct:

```bash
az account list --output table  # Get correct ID
```

### Error: "location is invalid"

```
InvalidTemplate: The location 'eastus' is invalid
```

**Solution**: Change region in `terraform.tfvars` to `westus`, `centralus`, or other valid Azure region.

### State file not created

```bash
# If terraform.tfstate doesn't exist after apply, check:
ls -la  # Look for terraform.tfstate file

# If missing, something failed - check error messages from apply
```

---

## What You Learned

- **Terraform syntax**: `resource "provider_type" "name"`
- **Variables**: Reusable values defined in `variables.tf`, set in `terraform.tfvars`
- **Outputs**: Display important resource info after deployment
- **Providers**: Azure provider handles authentication and resource creation
- **State**: Terraform stores resource info in local `terraform.tfstate` file
- **Workflow**: init → validate → plan → apply → (destroy)

---

## Next: Module 2 Preview

In Module 2, you'll:
1. **Migrate state to Azure Storage** (remote backend)
2. **Create reusable modules** for hub, spoke, firewall
3. **Organize code for scalability**

Before moving to Module 2, make sure:
- You can run `terraform apply` and see resources in Azure Portal
- You can run `terraform destroy` and see resources deleted
- You understand what each file does (provider.tf, variables.tf, main.tf, outputs.tf, backend.tf)

---

## Key Files in Module 1

```
/dev/
├── provider.tf          # Azure provider setup + authentication
├── variables.tf         # Variable definitions (what can be configured)
├── terraform.tfvars     # Variable values (YOUR Azure IDs)
├── main.tf              # Resource definitions (what to create)
├── outputs.tf           # Output definitions (what to display)
├── backend.tf           # State storage config (local for now)
└── terraform.tfstate    # CREATED AFTER APPLY - tracks resources
```

---

## Tips for Success

1. **Read error messages carefully**: Terraform errors tell you exactly what's wrong
2. **Always plan before apply**: `terraform plan` shows what will happen
3. **Keep state file safe**: Never delete `terraform.tfstate` manually
4. **Use meaningful names**: Makes code readable and Azure resources easier to find
5. **Tag resources**: Helps organize and track costs in Azure Portal
6. **Comment your code**: Future you will thank present you
7. **Save terraform.tfstate backups**: If state is corrupted, you can restore from backup

---

## Resources

- [Terraform Docs](https://www.terraform.io/docs)
- [Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Docs](https://learn.microsoft.com/en-us/cli/azure/)
