# SimpleReceiptImages Deployment Guide

This guide explains how to deploy the SimpleReceiptImages contract to Lisk Sepolia testnet.

## Prerequisites

1. **Environment Setup**: Create a `.env` file with:
```bash
PRIVATE_KEY=your_private_key_here
LISK_SEPOLIA_RPC_URL=https://rpc.sepolia-api.lisk.com
BLOCKSCOUT_API_KEY=your_api_key (optional)
CHAIN_ID=4202
```

2. **Foundry Installation**: Make sure you have Foundry installed
3. **Test Tokens**: Ensure your wallet has Lisk Sepolia ETH for gas

## Deployment Methods

### Method 1: Using Bash Script (Recommended)
```bash
# Make script executable
chmod +x deploy.sh

# Deploy to Lisk Sepolia
./deploy.sh

# Or deploy to specific network
./deploy.sh lisk_sepolia
```

### Method 2: Using Forge Command
```bash
# Load environment variables
source .env

# Deploy contract
forge script script/DeploySimpleReceiptImages.sol:DeploySimpleReceiptImages \
    --rpc-url lisk_sepolia \
    --broadcast \
    --legacy \
    -vv
```

### Method 3: Deploy and Test
```bash
# Deploy and run basic functionality test
forge script script/DeployAndTest.sol:DeployAndTest \
    --rpc-url lisk_sepolia \
    --broadcast \
    --legacy \
    -vv
```

## Post-Deployment Verification

### Verify Contract on Blockscout
```bash
# Set contract address
export CONTRACT_ADDRESS=0xYourContractAddress

# Verify contract
forge script script/VerifyContract.sol:VerifyContract \
    --rpc-url lisk_sepolia \
    -vv
```

### Run Tests
```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/simpleReceipt.t.sol -vv

# Run with gas reporting
forge test --gas-report
```

## Contract Information

- **Contract Name**: SimpleReceiptImages
- **Symbol**: SRCPT
- **Network**: Lisk Sepolia (Chain ID: 4202)
- **Interface**: ERC721 + ERC721URIStorage + Ownable

## Usage Examples

After deployment, you can interact with the contract:

```solidity
// Store a receipt image IPFS CID
uint256 tokenId = contract.storeReceiptImage("QmYourIPFSHashHere");

// Get the stored CID
string memory cid = contract.getImageCID(tokenId);

// Get the IPFS URL
string memory url = contract.getImageURL(tokenId);

// Get total images stored
uint256 total = contract.totalImages();
```

## Deployment Output

After successful deployment, you'll see:
```
=== Deployment Complete ===
Contract Address: 0x...
Deployer: 0x...
Chain ID: 4202
Block Number: ...
You can now interact with the contract!
```

## Troubleshooting

### Common Issues:

1. **Insufficient Balance**: Ensure wallet has enough ETH for gas
2. **RPC URL Issues**: Verify the RPC URL is correct and accessible
3. **Private Key Issues**: Ensure private key is correctly formatted (with 0x prefix)

### Gas Optimization:
- Each image storage costs ~300k gas
- Use `--legacy` flag for better compatibility
- Monitor gas prices on Lisk Sepolia

## Security Notes

- ⚠️ Never commit your `.env` file to version control
- ⚠️ Use a dedicated deployment wallet, not your main wallet
- ⚠️ Verify contract addresses before interacting
- ✅ Test thoroughly on testnet before mainnet deployment

## Contract Features

- **IPFS CID Storage**: Store receipt image CIDs on-chain
- **NFT Minting**: Each stored image becomes an NFT
- **Duplicate Prevention**: Prevents storing the same CID twice
- **Base64 Metadata**: Generates JSON metadata with IPFS links
- **Owner Management**: Contract has transferable ownership
- **Gas Efficient**: Optimized for reasonable gas costs

## Links

- **Lisk Sepolia Explorer**: https://sepolia-blockscout.lisk.com/
- **Lisk Sepolia Faucet**: https://sepolia-faucet.lisk.com/
- **Contract Repository**: [Your repo URL]