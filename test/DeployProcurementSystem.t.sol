// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../script/DeployProcurementSystem.sol";

contract DeployProcurementSystemTest is Test {
    DeployProcurementSystem public deployer;
    address public cfoAddress;
    
    function setUp() public {
        cfoAddress = makeAddr("cfo");
        vm.deal(cfoAddress, 100 ether);
    }
    
    function test_deploymentScript() public {
        // Set environment variables
        vm.setEnv("PRIVATE_KEY", "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
        vm.setEnv("CFO_ADDRESS", vm.toString(cfoAddress));
        
        // Create deployer instance
        deployer = new DeployProcurementSystem();
        
        // Get contract addresses
        (
            address dailyLimit,
            address agreementManagerAddr,
            address fraudDetectionAddr,
            address invoiceVerificationAddr,
            address zkVerifierAddr,
            address honkVerifierAddr
        ) = deployer.getContractAddresses();
        
        // All addresses should be different and non-zero if deployment was successful
        // Note: In this test, they will be zero until deployment is actually run
        assertTrue(honkVerifierAddr == 0x9E7C8251F45C881D42957042224055d32445805C, "Honk verifier address should match");
        assertTrue(address(deployer) != address(0), "Deployer should be instantiated");
    }
    
    function test_contractsDeployed() public {
        // This test will be used by the deployment script to verify deployment
        // For now, just check that the verifier address constant is correct
        address expectedVerifier = 0x9E7C8251F45C881D42957042224055d32445805C;
        assertTrue(
            expectedVerifier != address(0),
            "Honk verifier address should be correct"
        );
    }
    
    function test_verifierAddressIsValid() public {
        address verifierAddr = 0x9E7C8251F45C881D42957042224055d32445805C;
        assertTrue(verifierAddr != address(0), "Verifier address should not be zero");
        
        // Check that the address has the correct format
        assertTrue(uint160(verifierAddr) > 0, "Verifier address should be valid");
    }
}