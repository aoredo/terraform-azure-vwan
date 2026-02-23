#!/bin/bash
# ===== DESTROY RESOURCES SAFELY =====
# This script destroys dev environment resources
# Protect against cost overruns by running this daily

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== DEV ENVIRONMENT DESTROY ===${NC}"
echo "This will delete all dev resources in Azure"
echo ""

# First confirmation
read -p "Are you sure you want to destroy dev resources? (yes/no): " confirm1
if [ "$confirm1" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

# Second confirmation (extra safety)
read -p "Type 'destroy' to confirm (cannot be undone): " confirm2
if [ "$confirm2" != "destroy" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo -e "${RED}Destroying dev resources...${NC}"

cd dev

# Destroy resources
terraform destroy -auto-approve

echo ""
echo -e "${GREEN}Dev resources destroyed${NC}"
echo "State file still in Azure Storage (can redeploy anytime)"
echo ""
echo -e "${YELLOW}Cost Impact:${NC}"
echo "- Dev resources: now $0/day (all deleted)"
echo "- Storage backend: ~$0.50/month (minimal)"
echo ""
