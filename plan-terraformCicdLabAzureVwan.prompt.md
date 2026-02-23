# 5-Module Terraform CI/CD Lab for Azure VWAN

**TL;DR:** We're building a **progressive learning laboratory** that takes you from zero coding to enterprise-grade infrastructure management in 1-2 weeks. You'll create both `dev/` and `prod/` environments with a **multi-region DR architecture**: WestUS (primary) + EastUS (DR) with hub-spoke VWAN topology in each region, region-specific firewalls, and **central firewall management** via Azure Firewall Manager. Each module builds on the previous one: start with basic Terraform syntax and Azure authentication → progressively add modules, state management, VPN connectivity, single-region VWAN → finish with multi-region DR setup, central firewall policies, and automated CI/CD pipelines. By the end, you'll have deployed production-grade infrastructure across two regions and understand how to manage it at work.

---

## Steps

1. **Module 1: Terraform Foundations & Azure Auth (Days 1-2)**
   - Learn Terraform syntax: resources, variables, outputs, data sources
   - Set up Azure provider authentication (OIDC recommended for CI/CD safety)
   - Create `dev/basics/` folder structure with first Azure resource (resource group + VWAN hub VNet)
   - Verify: Deploy to Azure and see the VNet in portal

2. **Module 2: State Management & Modules (Days 3-4)**
   - Understand Terraform state (why it matters, local vs remote)
   - Migrate to remote state in Azure Storage Account
   - Refactor code into reusable modules: `modules/hub/`, `modules/firewall/`, `modules/spoke/`
   - Create module variables and outputs
   - Verify: Destroy and re-deploy using modules—should work identically

3. **Module 3: Hub-Spoke with VNet Peering & Firewall (Days 5-6)**
   - Build traditional hub-spoke: central hub VNet + firewall + Route Server
   - Create first spoke VNet and connect via VNet peering
   - Configure user-defined routing (UDR) for hub routing
   - Add Azure Firewall with basic allow/deny rules
   - Use modules to make spoke creation reusable
   - Verify: Ping between VNets confirms connectivity; firewall enforces rules

4. **Module 4: Migrate to Azure VWAN & Add VPN (Week 2, Days 1-2)**
   - **Why VWAN?** Understand limitations of traditional hub-spoke (manual routing, peering management) vs VWAN's built-in fabric
   - Refactor: Replace VNet peering with Azure VWAN hub + Azure Firewall Manager
   - Migrate firewall rules to VWAN Firewall Manager policy
   - Add VPN gateway to VWAN hub (site-to-site ready)
   - Add second spoke VNet to VWAN hub
   - Verify: VWAN hub seamlessly routes between spokes; VPN connection established

5. **Module 5: Multi-Region DR & Central Firewall Management (Week 2, Days 3-5)**
   - **DR Architecture**: Replicate WestUS prod environment to EastUS (VWAN hub + spoke + firewall)
   - **Region Connectivity**: Set up hub-to-hub peering between WestUS and EastUS VWAN hubs for resource replication
   - **Central Firewall Management**: Use Azure Firewall Manager to create unified firewall policies for both regions
   - Synchronize firewall rules across regions (single policy definition, deployed to both regional firewalls)
   - Configure failover routing: Traffic normally flows through WestUS; if primary fails, traffic reroutes to EastUS
   - **GitHub Actions CI/CD**: Set up workflows that deploy to both regions simultaneously (`westus-apply.yml`, `eastus-apply.yml`)
   - Add `prod/terraform.tfvars` with region-specific settings (regions, firewall SKUs, replica flags)
   - Implement safety guardrails: `prevent_destroy` on all prod resources, strict naming conventions with region prefixes (e.g., `prod-wus-`, `prod-eus-`)
   - **DR Testing**: Simulate WestUS failure, verify traffic automatically fails over to EastUS; simulate recovery
   - Document: Multi-region diagrams, DR runbook, failover procedures, central firewall policy management
   - Verify: Both regions deployed, central firewall policy manages both, failover testing successful, CI/CD deploys to both regions

---

## File Structure You'll Create

```
/dev/
  ├── main.tf              (single-region hub resources)
  ├── variables.tf
  ├── terraform.tfvars
  ├── outputs.tf
  └── backend.tf           (Azure Storage state)

/prod/
  ├── westus/              (PRIMARY REGION - WestUS)
  │   ├── main.tf
  │   ├── variables.tf
  │   ├── terraform.tfvars
  │   ├── outputs.tf
  │   └── backend.tf
  │
  ├── eastus/              (DR REGION - EastUS, replica of westus)
  │   ├── main.tf
  │   ├── variables.tf
  │   ├── terraform.tfvars
  │   ├── outputs.tf
  │   └── backend.tf
  │
  └── central/             (Shared resources: hub-to-hub peering, Firewall Manager policy)
      ├── main.tf
      ├── variables.tf
      ├── outputs.tf
      └── backend.tf

/modules/
  ├── hub/                 (Hub VNet for hub-spoke networking, region-agnostic)
  │   ├── main.tf
  │   ├── variables.tf
  │   └── outputs.tf
  ├── spoke/               (VNet spoke for both architectures)
  │   ├── main.tf
  │   ├── variables.tf
  │   └── outputs.tf
  ├── firewall/            (Azure Firewall, region-specific)
  │   ├── main.tf
  │   ├── variables.tf
  │   └── outputs.tf
  ├── firewall-policy/     (Firewall Manager policy - managed from central location)
  │   ├── main.tf
  │   ├── variables.tf
  │   └── outputs.tf
  ├── vwan/                (Azure VWAN hub, gateway, region-specific)
  │   ├── main.tf
  │   ├── variables.tf
  │   └── outputs.tf
  ├── vpn/                 (VPN gateway for hub-spoke & VWAN)
  │   ├── main.tf
  │   ├── variables.tf
  │   └── outputs.tf
  └── hub-peering/         (Hub-to-hub peering between regions for DR)
      ├── main.tf
      ├── variables.tf
      └── outputs.tf

/.github/workflows/
  ├── dev-plan-apply.yml        (DEV: plan on PR, apply on merge to main)
  ├── prod-westus-apply.yml     (PROD WestUS: plan on PR, apply on merge)
  ├── prod-eastus-apply.yml     (PROD EastUS: plan on PR, apply on merge)
  └── prod-dr-failover-test.yml (Manual trigger: test failover from WestUS to EastUS)

/scripts/
  ├── destroy-dev.sh       (Safely destroys all dev resources)
  ├── destroy-prod.sh      (Safely destroys all prod resources in both regions, requires approval)
  ├── estimate-cost.sh     (Estimates current resource costs in both regions)
  └── test-dr-failover.sh  (Simulates WestUS failure, verifies EastUS takeover)

/docs/
  ├── ARCHITECTURE.md            (single-region and multi-region diagrams, DR topology)
  ├── DEPLOYMENT.md              (step-by-step deployment guide for both regions)
  ├── TEARDOWN.md                (how to destroy resources daily to save costs)
  ├── FIREWALL-MANAGEMENT.md     (central firewall policy management guide)
  ├── DR-PROCEDURES.md           (failover, recovery, testing procedures)
  └── TROUBLESHOOTING.md         (common errors and fixes)

---

## Key Decisions

- **Multi-Region DR from Day 1**: Introduce region variables early; scale to WestUS + EastUS in Module 5. Teaches production-grade infrastructure patterns
- **Progressive Architecture**: Start with traditional **hub-spoke + VNet peering** (understand the limitations) → evolve to **Azure VWAN** (the modern, scalable approach) → extend to **multi-region VWAN with central firewall management** (enterprise DR pattern)
- **Folder-based environments** (not workspaces initially): Easier to understand separation for beginners; `dev/` single-region, `prod/westus/` + `prod/eastus/` + `prod/central/`
- **Hub-spoke baseline + 2 spokes per region**: X2 for multi-region = realistic prod load. Teaches both architecture patterns and multi-region complexity
- **Central Firewall Management**: Use Azure Firewall Manager to define firewall policies once, deploy to both regions. Prevents policy drift and reduces management overhead
- **Hub-to-Hub Peering for DR**: WestUS hub connects to EastUS hub for seamless failover; traffic reroutes automatically when primary fails
- **Remote state from Day 1**: Prevents the biggest Terraform disaster; uses separate Azure Storage containers per region
- **GitHub Actions with region-specific workflows**: Each region deploys independently but coordinates via shared state; approval gates for prod
- **Modular code**: Reusable modules parameterized by region; scales to add more regions later
- **OIDC authentication**: Better security than static secrets; single auth for both regions
- **Cost Management**: Multi-region = 2x cost; even more critical to destroy resources daily (~$1-3/day for 2 regions vs $30+/day if left running)

---

## Cost Management Strategy

**Problem**: Azure resources like VWAN, Firewall, and VPN gateways cost ~$15-50/day **per region** when idle. Two regions = $30-100/day, making continuous lab deployment expensive.

**Solution**: Daily teardown and rebuild

- **Each morning**: Run `terraform apply` in dev/ and prod/westus/ (~10 min for both)
- **Each evening**: Run `destroy-prod.sh` to tear down WestUS and EastUS prod, keep dev for morning (~5 min)
- **Cost**: ~$1-3/day for one day of learning (vs $30-100/day if left running 24/7)
- **WestUS is primary, EastUS is removed during daily teardown**: Rebuild EastUS only in final Module 5 when testing DR failover

**Teardown Scripts**:
- `destroy-dev.sh`: Simple `terraform destroy` automation for dev environment, one confirmation prompt
- `destroy-prod.sh`: Destroys both WestUS and EastUS prod, two-prompt approval (extra safety for reaching both regions)
- `estimate-cost.sh`: Queries Azure for current resource costs per region before/after teardown
- `test-dr-failover.sh`: Temporarily brings up EastUS, simulates WestUS failure, tests failover, then tears down both

**Safety Guardrails**:
- Terraform state files **backed up daily** to separate Azure Storage containers per region
- `prevent_destroy` lifecycle rule on all prod resources (blocks accidental deletion of critical infrastructure)
- Dev script requires one confirmation; prod script requires two confirmations (region confirmation + final approval)
- Hub-to-hub peering disabled by default; only created during DR testing (further reduces standby costs)

---

## Verification & Success Criteria

By end of each module:
- **Module 1**: Hub VNet visible in Azure portal, can ping within VNet; successfully destroyed using `destroy-dev.sh` with zero resources remaining
- **Module 2**: Destroy resources, re-apply modules, infrastructure re-created identically; state persists in Azure Storage even after destruction
- **Module 3**: Hub-spoke with VNet peering working, firewall rules enforce allow/deny, spoke VNets communicate through hub; daily teardown/rebuild successful
- **Module 4**: Successfully migrated to VWAN hub in WestUS only; firewall rules migrated to Firewall Manager; second spoke added; VPN connection established and verified; single-region resource cost ~$15-25/day
- **Module 5**: Multi-region DR setup complete—WestUS (primary) and EastUS (DR) both deployed with identical VWAN + spoke topology; central firewall policy manages both regions; hub-to-hub peering established; CI/CD workflows deploy to both regions simultaneously; DR failover test successful (simulate WestUS outage → traffic reroutes to EastUS → verify connectivity); both regions destroyed for cost savings; can deploy either region independently or both simultaneously; total cost ~$2-4/day when both regions deployed
