// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SimpleReceiptImages.sol";

contract DeploySimpleReceiptImages is Script {
    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== SimpleReceiptImages Deployment ===");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance / 1e18, "ETH");
        console.log("Chain ID:", block.chainid);
        
        // Verify minimum balance
        require(deployer.balance > 0.001 ether, "Insufficient balance for deployment");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the contract
        console.log("Deploying SimpleReceiptImages...");
        SimpleReceiptImages receiptContract = new SimpleReceiptImages();
        
        // Stop broadcasting
        vm.stopBroadcast();
        
        console.log("=== Deployment Successful ===");
        console.log("Contract address:", address(receiptContract));
        console.log("Contract name:", receiptContract.name());
        console.log("Contract symbol:", receiptContract.symbol());
        console.log("Contract owner:", receiptContract.owner());
        console.log("Total supply:", receiptContract.totalImages());
        
        // Verify contract functionality
        console.log("=== Post-deployment Verification ===");
        
        // Check if contract supports ERC721 interface
        bool supportsERC721 = receiptContract.supportsInterface(0x80ac58cd);
        console.log("Supports ERC721:", supportsERC721);
        
        // Check if contract supports ERC721Metadata interface  
        bool supportsMetadata = receiptContract.supportsInterface(0x5b5e139f);
        console.log("Supports ERC721Metadata:", supportsMetadata);
        
        console.log("=== Deployment Complete ===");
        console.log("Contract Address:", address(receiptContract));
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Block Number:", block.number);
        console.log("You can now interact with the contract!");
    }
}