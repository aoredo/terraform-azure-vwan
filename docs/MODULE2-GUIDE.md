# Module 2: State Management & Modules

## Overview

In this module, you'll learn:
- Terraform state: what it is and why it matters
- Remote state: migrate from local to Azure Storage
- Terraform modules: reusable, composable code
- Module best practices

**Estimated Time**: 2-3 hours  
**Prerequisites**: Completed Module 1  
**Success**: Deploy using modules with remote state, then destroy and redeploy identically

---

## Part 1: Understanding Terraform State

### What is State?

**State** = Terraform's database of infrastructure

When you run `terraform apply`, Terraform:
1. Reads your `.tf` files (code)
2. Talks to Azure (via API)
3. **Stores information about created resources in state file**

Example state file entry:
```json
{
  "type": "azurerm_virtual_network",
  "id": "hub_vnet",
  "instances": [{
    "attributes": {
      "id": "/subscriptions/xxx/resourceGroups/rg-terraform-lab-dev/providers/Microsoft.Network/virtualNetworks/vnet-hub-dev",
      "name": "vnet-hub-dev",
      "address_space": ["10.0.0.0/16"],
      "location": "uksouth"
    }
  }]
}
```

### Why State is Critical

#### Scenario 1: Without State
```bash
terraform apply  # Creates 3 resources
terraform apply  # Again creates 3 MORE resources (duplicates!)
# Now you have 6 resources (two of everything - disaster!)
```

#### Scenario 2: With State
```bash
terraform apply  # Creates 3 resources, stores in state
terraform apply  # Checks state: "3 resources already exist", changes nothing
# Safe: resources aren't duplicated
```

### State Contains Sensitive Information

State file includes:
- Resource IDs and properties
- Database passwords (if stored in TF)
- Connection strings
- SSH private keys
- API tokens

**NEVER** commit state to Git! (Already in .gitignore for prod)

---

## Part 2: Local State (Module 1) vs Remote State (Module 2)

### Module 1: Local State

**Location**: `dev/terraform.tfstate` (in your folder)

**Pros**:
- Simple - works out of the box
- Good for learning
- Single-person labs

**Cons**:
- If laptop crashes, state is lost
- Only ONE person can use it
- Can't use in CI/CD (GitHub Actions can't access local file)
- Hard to backup

### Module 2: Remote State

**Location**: Azure Storage Account (in the cloud)

**Pros**:
- Multiple people access same state
- Automatic backups by Azure
- CI/CD can access it (GitHub Actions)
- Built-in locking (prevents concurrent modifications)
- Secure (Azure manages access control)

**Cons**:
- Slightly more setup (bootstrap)
- Small cost (~$1/month) for storage

---

## Part 3: Setting Up Remote State - Step By Step

### Step 1: Examine Bootstrap Terraform

```bash
ls -la bootstrap/
# See:
# - provider.tf
# - variables.tf
# - main.tf
# - outputs.tf
# - terraform.tfvars
```

Bootstrap creates:
- Resource Group: `rg-terraform-state`
- Storage Account: `tfstatetdops2026`
- Containers: `tfstate-dev`, `tfstate-prod`

### Step 2: Configure Bootstrap Variables

Edit `bootstrap/terraform.tfvars`:

```hcl
azure_subscription_id = "90b5b034-bc5b-43a3-a49e-b3eb350ca3b6"
azure_tenant_id       = "28043c66-dc47-4da8-b48f-60617dbd4239"
backend_storage_account_name = "tfstatetdops2026"  # CHANGE THIS: Must be globally unique
backend_region = "uksouth"
```

**Important**: Storage account name must be:
- 3-24 characters
- Lowercase letters and numbers only
- **Globally unique** (no other Azure account in world can use same name)

**If you get error "storage account name already taken"**:
- Change to something unique like `tfstatetdops<yourname>2026`

### Step 3: Deploy Bootstrap

```bash
cd bootstrap

# Initialize bootstrap Terraform
terraform init

# Verify bootstrap code
terraform validate

# Preview what will be created
terraform plan

# Create the storage account (ONE TIME ONLY)
terraform apply
# Answer: yes

# You should see outputs like:
# backend_storage_account_name = "tfstatetdops2026"
# dev_container_name = "tfstate-dev"
```

**What happened**: Azure now has a storage account with two containers ready to store state

### Step 4: Update dev/backend.tf

In `dev/backend.tf`, update these values to match bootstrap outputs:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "tfstatetdops2026"
  container_name       = "tfstate-dev"
  key                  = "terraform.tfstate"
}
```

### Step 5: Migrate State in dev/

```bash
cd dev

# This will read your bootstrap outputs and ask to migrate state
terraform init

# Terraform asks:
# "Do you want to copy existing state from the prior backend to the newly configured backend?"
# Answer: yes

# Migration complete! State is now in Azure
```

### Step 6: Verify Remote State

Go to Azure Portal:
1. Search: "storage accounts"
2. Click: `tfstatetdops2026`
3. Left sidebar: "Containers"
4. Click: `tfstate-dev`
5. You should see: `terraform.tfstate` file

**Congratulations!** State is now remote and shared.

### Step 7: Cleanup Local State (Optional)

```bash
cd dev

# Delete the local state file (no longer needed)
rm -f terraform.tfstate
rm -f terraform.tfstate.backup

# Verify it's gone
ls -la
# Should NOT see terraform.tfstate anymore

# Run terraform to confirm it uses remote state
terraform state list
# Should work fine (reading from Azure Storage)
```

---

## Part 3: Understanding Terraform Modules

### What is a Module?

A **module** is a directory of Terraform code that can be used/reused.

**Example**:
```
modules/
├── hub/           ← Module 1: creates hub VNet + subnets
├── spoke/         ← Module 2: creates spoke VNet + subnets
└── firewall/      ← Module 3: creates Azure Firewall (we'll add later)
```

### Why Modules?

**Scenario Without Modules** (Module 1):
```hcl
# Create hub
resource "azurerm_virtual_network" "hub" { ... }
resource "azurerm_subnet" "hub_mgmt" { ... }

# Create spoke 1
resource "azurerm_virtual_network" "spoke1" { ... }
resource "azurerm_subnet" "spoke1_workload" { ... }

# Create spoke 2
resource "azurerm_virtual_network" "spoke2" { ... }
resource "azurerm_subnet" "spoke2_workload" { ... }

# Result: 100 lines of repetitive code
```

**Scenario With Modules** (Module 2):
```hcl
module "hub" {
  source = "../modules/hub"
  hub_name = "vnet-hub"
  # ...
}

module "spoke1" {
  source = "../modules/spoke"
  spoke_name = "vnet-spoke1"
  # ...
}

module "spoke2" {
  source = "../modules/spoke"
  spoke_name = "vnet-spoke2"
  # ...
}

# Result: 20 lines, crystal clear, reusable
```

### Module Structure

```
modules/hub/
├── main.tf          ← Module code (resource definitions)
├── variables.tf     ← Input variables (what caller can configure)
└── (no outputs.tf yet in our example)
```

In `modules/hub/main.tf`:
- Define `variable "..."` blocks (inputs)
- Create resources
- Define `output "..."` blocks (what to return to caller)

### Using a Module (Module Call)

In `dev/main.tf`:
```hcl
module "hub_network" {
  source = "../modules/hub"  # Where the module code is

  # Pass variables to module
  hub_name = var.hub_vnet_name
  hub_address_space = var.hub_vnet_address_space
  # ... other variables ...
  
  tags = var.tags
}
```

Then reference module outputs:
```hcl
output "hub_vnet_id" {
  value = module.hub_network.hub_vnet_id
}
```

### Our Modules in Module 2

We created:
- `modules/hub/` → creates hub VNet + subnets
- `modules/spoke/` → creates spoke VNet + subnets
- `modules/firewall/` → placeholder (completed in Module 3)
- `modules/vwan/` → placeholder (completed in Module 4)

---

## Part 4: Deploy Module 2 - Step By Step

### Step 1: Verify File Structure

```bash
# From project root
ls -la

# Should see:
# bootstrap/
# modules/
# dev/
# prod/
# docs/
# scripts/
```

### Step 2: Initialize dev/ with Modules and Remote State

```bash
cd dev

# Initialize Terraform
# This will:
# 1. Download Azure provider
# 2. Connect to Azure Storage for state
terraform init

# Validate the code (with modules)
terraform validate

# Should output: Success! The configuration is valid.
```

### Step 3: Plan with Modules

```bash
# Preview changes (same as Module 1, but now uses modules)
terraform plan

# Output will show module resources:
# Module 1: module.hub_network
# Terraform will perform the following actions:
# + module.hub_network.azurerm_virtual_network.hub
# + module.hub_network.azurerm_subnet.hub_subnets["management"]
# ...
```

### Step 4: Apply with Modules

```bash
# Deploy infrastructure (uses modules)
terraform apply

# Answer: yes

# Output should show:
# Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
#
# Outputs:
# hub_resource_group_id = "..."
# hub_vnet_id = "..."
# hub_subnet_ids = { "management" = "..." }
```

### Step 5: Verify in Azure Portal

Same as Module 1:
- Go to https://portal.azure.com
- Search "Resource Groups"
- Find `rg-terraform-lab-dev`
- Should see hub VNet and subnet

---

## Part 5: Testing Module Reusability

### Create Spoke Using Module

In `dev/main.tf`, add:

```hcl
module "spoke1" {
  source = "../modules/spoke"

  resource_group_name = azurerm_resource_group.hub.name
  location            = var.region
  spoke_name          = "vnet-spoke1-dev"
  spoke_address_space = "10.1.0.0/16"

  subnets = {
    "workload" = {
      address_prefix = "10.1.0.0/24"
      description    = "Workload subnet"
    }
  }

  tags = var.tags

  depends_on = [azurerm_resource_group.hub]
}
```

Then add output:
```hcl
output "spoke1_vnet_id" {
  value = module.spoke1.spoke_vnet_id
}
```

Then deploy:
```bash
terraform plan    # Shows spoke1 being created
terraform apply   # Creates spoke1
```

Now you have:
- Hub VNet (from hub module)
- Spoke1 VNet (from spoke module)

Both created with few lines of code!

---

## Part 6: Test Destroy and Redeploy

This is the critical test: **idempotency** (can you destroy and redeploy identically?)

### Destroy All Resources

```bash
terraform destroy

# Answers: yes

# Output:
# Destroy complete! Resources: 3 destroyed
```

### Redeploy Everything

```bash
terraform apply

# Answers: yes

# Output:
# Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

**Success!** If this works, you've proven:
- Modules work correctly
- State is properly managed
- Code is reproducible

---

## Troubleshooting

### Error: "Storage account already taken"

```bash
Error: checking for existing storage account name: 
  storage accounts with name tfstatetdops2026 already exist
```

**Solution**: Change storage account name in `bootstrap/terraform.tfvars` to something unique:
```hcl
backend_storage_account_name = "tfstatetdops<yourcompany>2026"
```

### Error: "Module not found"

```bash
Error: Module not found
  on main.tf line 5, in module "hub_network":
  5:   source = "../modules/hub"

No module matching supplied source text
```

**Solution**: Verify `modules/hub/main.tf` exists:
```bash
ls -la ../modules/hub/
# Should see main.tf
```

### Error: "Cannot use module with 0 remote backends available"

```bash
Error:  Backend initialization required.
```

**Solution**: Run bootstrap first:
```bash
cd ../bootstrap
terraform apply
cd ../dev
terraform init
```

---

## Module 2 Success Checklist

✅ Bootstrap Terraform deployed (storage account created)  
✅ Updated `dev/backend.tf` with storage account details  
✅ `terraform init` succeeded (state migrated to Azure)  
✅ `terraform plan` shows 3 resources (RG + hub VNet + subnet)  
✅ `terraform apply` deployed successfully  
✅ Resources visible in Azure Portal  
✅ Created spoke module call  
✅ `terraform destroy` removed all resources  
✅ `terraform apply` re-created resources identically  
✅ Understand modules (`source`, `inputs`, `outputs`)  

---

## Key Concepts Learned

| Concept | What | Why |
|---------|------|-----|
| **State** | Database of resources | Terraform needs to track what it created |
| **Local State** | File in dev/ folder | Simple, but only works for one person |
| **Remote State** | File in Azure Storage | Multiple people, CI/CD, auto-backups |
| **State Locking** | Azure prevents concurrent edits | Two people can't apply at same time |
| **Module** | Reusable Terraform code | Don't repeat yourself |
| **Module Call** | Using a module | `module "name" { source = "..." }` |
| **Module Outputs** | Exporting values from module | `module.HUB.OUTPUT_NAME` |

---

## Files Changed in Module 2

```
bootstrap/                    (NEW)
  ├── provider.tf
  ├── variables.tf
  ├── main.tf
  ├── outputs.tf
  └── terraform.tfvars

modules/                      (ENHANCED)
  ├── hub/
  │   └── main.tf            (NEW - reusable hub module)
  ├── spoke/
  │   └── main.tf            (NEW - reusable spoke module)
  ├── firewall/
  │   └── main.tf            (PLACEHOLDER)
  ├── vwan/
  │   └── main.tf            (PLACEHOLDER)
  └── vpn/
      └── main.tf            (PLACEHOLDER)

dev/                          (REFACTORED)
  ├── main.tf                (NOW uses hub module)
  ├── outputs.tf             (NOW references module outputs)
  ├── backend.tf             (NOW uses remote state)
  ├── provider.tf            (unchanged)
  ├── variables.tf           (unchanged)
  └── terraform.tfstate*     (deleted - now in Azure Storage)
```

---

## Next: Module 3 Preview

In Module 3, you'll:
1. Add Azure Firewall to hub
2. Create firewall rules
3. Test connectivity between hub and spoke
4. Learn about routing and firewall policies

Before moving to Module 3:
- Ensure bootstrap and dev both deploy/destroy successfully
- Understand modules and state management
- Be able to explain: "Why is remote state important for teams?"

---

## Resources

- [Terraform Modules Docs](https://www.terraform.io/language/modules)
- [Terraform State](https://www.terraform.io/language/state)
- [Azure Storage Terraform Backend](https://www.terraform.io/language/settings/backends/azurerm)
