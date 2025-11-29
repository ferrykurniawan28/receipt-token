// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SimpleReceiptImages.sol";

contract DeployAndTest is Script {
    SimpleReceiptImages public receiptContract;
    
    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Deploy and Test SimpleReceiptImages ===");
        console.log("Deployer address:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "ETH");
        
        // Start broadcasting
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy contract
        receiptContract = new SimpleReceiptImages();
        console.log("Contract deployed at:", address(receiptContract));
        
        // Test basic functionality
        testBasicFunctionality();
        
        vm.stopBroadcast();
        
        console.log("=== Deployment and Testing Complete ===");
    }
    
    function testBasicFunctionality() internal {
        console.log("=== Testing Basic Functionality ===");
        
        // Test storing a receipt image
        string memory testCID = "QmTestDeployment123abc";
        console.log("Storing test CID:", testCID);
        
        uint256 tokenId = receiptContract.storeReceiptImage(testCID);
        console.log("Token ID created:", tokenId);
        
        // Verify the CID was stored correctly
        string memory storedCID = receiptContract.getImageCID(tokenId);
        console.log("Stored CID:", storedCID);
        
        // Check total images
        uint256 total = receiptContract.totalImages();
        console.log("Total images:", total);
        
        // Check owner
        address owner = receiptContract.ownerOf(tokenId);
        console.log("Token owner:", owner);
        
        // Get image URL
        string memory imageURL = receiptContract.getImageURL(tokenId);
        console.log("Image URL:", imageURL);
        
        console.log("Basic functionality test passed!");
    }
}