// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SimpleReceiptImages.sol";

contract DeploySimpleReceiptImages is Script {
    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the contract
        console.log("Deploying SimpleReceiptImages...");
        SimpleReceiptImages receiptContract = new SimpleReceiptImages();
        
        // Stop broadcasting
        vm.stopBroadcast();
        
        console.log("SimpleReceiptImages deployed successfully!");
        console.log("Contract address:", address(receiptContract));
        console.log("Network: Lisk Sepolia");
        console.log("Deployer:", deployer);
    }
}