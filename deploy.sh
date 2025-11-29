#!/bin/bash

# SimpleReceiptImages Deployment Script
# Usage: ./deploy.sh [network]

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Please create a .env file with:"
    echo "PRIVATE_KEY=your_private_key"
    echo "LISK_SEPOLIA_RPC_URL=https://rpc.sepolia-api.lisk.com"
    exit 1
fi

# Load environment variables
source .env

# Check if private key is set
if [ -z "$PRIVATE_KEY" ]; then
    print_error "PRIVATE_KEY not set in .env file"
    exit 1
fi

# Check if RPC URL is set
if [ -z "$LISK_SEPOLIA_RPC_URL" ]; then
    print_error "LISK_SEPOLIA_RPC_URL not set in .env file"
    exit 1
fi

# Set network (default to lisk_sepolia)
NETWORK=${1:-lisk_sepolia}

print_status "Starting deployment to $NETWORK..."

# Build contracts
print_status "Building contracts..."
forge build

if [ $? -ne 0 ]; then
    print_error "Build failed"
    exit 1
fi

print_success "Build successful"

# Deploy contract
print_status "Deploying SimpleReceiptImages contract..."

forge script script/DeploySimpleReceiptImages.sol:DeploySimpleReceiptImages \
    --rpc-url $NETWORK \
    --broadcast \
    --legacy \
    -vvv

if [ $? -eq 0 ]; then
    print_success "Deployment successful!"
    
    # Show deployment info if file exists
    if [ -f deployment-info.txt ]; then
        print_status "Deployment details:"
        cat deployment-info.txt
    fi
    
    print_status "Transaction details saved in broadcast/ folder"
    print_success "Contract is ready to use!"
else
    print_error "Deployment failed"
    exit 1
fi