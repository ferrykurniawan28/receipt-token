#!/bin/bash

# Procurement System Deployment Script
# This script deploys the complete procurement system with ZK verification

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_NAME="DeployProcurementSystem"
CONTRACT_DIR="script"

# Default values (can be overridden by environment variables)
DEFAULT_RPC_URL="https://rpc.sepolia-api.lisk.com"
DEFAULT_CHAIN_ID="4202"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PROCUREMENT SYSTEM DEPLOYMENT${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if required environment variables are set
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY environment variable is not set${NC}"
    echo "Please set your private key: export PRIVATE_KEY=your_private_key_here"
    exit 1
fi

# Use environment variables or defaults
RPC_URL=${RPC_URL:-$DEFAULT_RPC_URL}
CHAIN_ID=${CHAIN_ID:-$DEFAULT_CHAIN_ID}
VERIFIER_AND_SEND=${VERIFIER_AND_SEND:-"true"}

echo -e "${YELLOW}Configuration:${NC}"
echo "RPC URL: $RPC_URL"
echo "Chain ID: $CHAIN_ID"
echo "Script: $SCRIPT_NAME"

# Check if CFO_ADDRESS is set, if not use deployer address
if [ -z "$CFO_ADDRESS" ]; then
    echo -e "${YELLOW}CFO_ADDRESS not set, will use deployer address as CFO${NC}"
fi

# Compile contracts
echo -e "\n${YELLOW}Compiling contracts...${NC}"
forge build --via-ir

if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Compilation successful${NC}"

# Check balance before deployment
echo -e "\n${YELLOW}Checking deployer balance...${NC}"
DEPLOYER_ADDRESS=$(cast wallet address $PRIVATE_KEY)
BALANCE=$(cast balance $DEPLOYER_ADDRESS --rpc-url $RPC_URL)
BALANCE_ETH=$(cast from-wei $BALANCE)

echo "Deployer address: $DEPLOYER_ADDRESS"
echo "Balance: $BALANCE_ETH ETH"

# Check if balance is sufficient (minimum 0.1 ETH)
BALANCE_CHECK=$(echo "$BALANCE_ETH > 0.1" | bc -l)
if [ "$BALANCE_CHECK" -eq 0 ]; then
    echo -e "${RED}Error: Insufficient balance. Need at least 0.1 ETH for deployment${NC}"
    exit 1
fi

# Deploy contracts
echo -e "\n${YELLOW}Deploying Procurement System...${NC}"
echo "This may take a few minutes..."

if [ "$VERIFIER_AND_SEND" = "true" ]; then
    # Deploy and verify contracts
    DEPLOY_OUTPUT=$(forge script $CONTRACT_DIR/$SCRIPT_NAME.sol:$SCRIPT_NAME \
        --rpc-url $RPC_URL \
        --broadcast \
        --verify \
        --via-ir \
        -vv 2>&1)
else
    # Deploy without verification
    DEPLOY_OUTPUT=$(forge script $CONTRACT_DIR/$SCRIPT_NAME.sol:$SCRIPT_NAME \
        --rpc-url $RPC_URL \
        --broadcast \
        --via-ir \
        -v 2>&1)
fi

DEPLOY_STATUS=$?

echo "$DEPLOY_OUTPUT"

if [ $DEPLOY_STATUS -ne 0 ]; then
    echo -e "\n${RED}Deployment failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}========================================${NC}"

# Extract contract addresses from deployment output
echo -e "\n${YELLOW}Extracting contract addresses...${NC}"

# Try to extract addresses from the deployment output
DAILY_LIMIT_ADDR=$(echo "$DEPLOY_OUTPUT" | grep "DailyLimitManager deployed at:" | awk '{print $4}' | tail -1)
AGREEMENT_ADDR=$(echo "$DEPLOY_OUTPUT" | grep "PurchaseAgreementManager deployed at:" | awk '{print $4}' | tail -1)
FRAUD_ADDR=$(echo "$DEPLOY_OUTPUT" | grep "FraudDetection deployed at:" | awk '{print $4}' | tail -1)
ZK_VERIFIER_ADDR=$(echo "$DEPLOY_OUTPUT" | grep "ZKInvoiceVerifier deployed at:" | awk '{print $4}' | tail -1)
INVOICE_ADDR=$(echo "$DEPLOY_OUTPUT" | grep "EnhancedInvoiceVerification deployed at:" | awk '{print $4}' | tail -1)

# Save deployment info to file
DEPLOYMENT_INFO_FILE="deployment_info_$(date +%Y%m%d_%H%M%S).txt"

cat > $DEPLOYMENT_INFO_FILE << EOF
Procurement System Deployment Information
=========================================
Deployment Date: $(date)
Network: Chain ID $CHAIN_ID
RPC URL: $RPC_URL
Deployer: $DEPLOYER_ADDRESS
CFO Address: ${CFO_ADDRESS:-$DEPLOYER_ADDRESS}

Contract Addresses:
==================
DailyLimitManager:           $DAILY_LIMIT_ADDR
PurchaseAgreementManager:    $AGREEMENT_ADDR  
FraudDetection:              $FRAUD_ADDR
ZKInvoiceVerifier:           $ZK_VERIFIER_ADDR
EnhancedInvoiceVerification: $INVOICE_ADDR

Referenced Contracts:
====================
Honk Verifier:               0x9E7C8251F45C881D42957042224055d32445805C

Environment Variables Used:
===========================
PRIVATE_KEY: [HIDDEN]
CFO_ADDRESS: ${CFO_ADDRESS:-"Not set (using deployer)"}
RPC_URL: $RPC_URL
CHAIN_ID: $CHAIN_ID

Initial Configuration:
=====================
- Electronics: 50 ETH daily limit
- Office Supplies: 10 ETH daily limit  
- Furniture: 30 ETH daily limit
- Software: 20 ETH daily limit
- Maintenance: 15 ETH daily limit

Testing Commands:
================
# Run all procurement tests
forge test --match-path test/procurement.t.sol --via-ir -vv

# Test with specific RPC
forge test --match-path test/procurement.t.sol --rpc-url $RPC_URL --via-ir -vv

# Verify contracts (if not done during deployment)
forge verify-contract <contract_address> <contract_name> --chain-id $CHAIN_ID --constructor-args \$(cast abi-encode "constructor(address)" "<cfo_address>")
EOF

echo -e "\n${GREEN}Deployment information saved to: $DEPLOYMENT_INFO_FILE${NC}"

# Display quick summary
echo -e "\n${BLUE}Quick Summary:${NC}"
echo "Network: Chain ID $CHAIN_ID"
if [ ! -z "$INVOICE_ADDR" ]; then
    echo -e "${GREEN}✓ Main Contract (EnhancedInvoiceVerification): $INVOICE_ADDR${NC}"
fi
if [ ! -z "$ZK_VERIFIER_ADDR" ]; then
    echo -e "${GREEN}✓ ZK Verifier: $ZK_VERIFIER_ADDR${NC}"
fi

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Run tests: forge test --match-path test/procurement.t.sol --via-ir -vv"
echo "2. Update your frontend/client to use the deployed contract addresses"
echo "3. Configure CFO address if needed: export CFO_ADDRESS=<cfo_wallet_address>"
echo -e "4. Check deployment details in: ${BLUE}$DEPLOYMENT_INFO_FILE${NC}"

# Verify deployment by running a simple test
echo -e "\n${YELLOW}Running quick deployment verification...${NC}"
forge test --match-test "test_contractsDeployed" --via-ir -v

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment verification successful!${NC}"
else
    echo -e "${YELLOW}⚠ Deployment verification failed - check manually${NC}"
fi

echo -e "\n${GREEN}Procurement system deployment complete!${NC}"