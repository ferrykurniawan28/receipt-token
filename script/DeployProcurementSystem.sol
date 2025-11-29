// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/ProcurementSystem.sol";
import "../src/MockVerifier.sol";

contract DeployProcurementSystem is Script {
    // Deployed Honk Verifier address (replace with actual deployed address)
    address public constant HONK_VERIFIER_ADDRESS = 0x9E7C8251F45C881D42957042224055d32445805C;
    
    // Contract instances
    DailyLimitManager public dailyLimitManager;
    PurchaseAgreementManager public agreementManager;
    FraudDetection public fraudDetection;
    ZKInvoiceVerifier public zkInvoiceVerifier;
    EnhancedInvoiceVerification public invoiceVerification;
    
    function run() external {
        // Get deployment key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address cfoAddress = vm.envOr("CFO_ADDRESS", deployer); // Use deployer as CFO if not specified
        
        console.log("========================================");
        console.log("PROCUREMENT SYSTEM DEPLOYMENT");
        console.log("========================================");
        console.log("Deployer address:", deployer);
        console.log("CFO address:", cfoAddress);
        console.log("Honk Verifier address:", HONK_VERIFIER_ADDRESS);
        console.log("Chain ID:", block.chainid);
        
        // Check deployer balance
        uint256 balance = deployer.balance;
        console.log("Deployer balance:", balance / 1e18, "ETH");
        require(balance > 0.1 ether, "Insufficient balance for deployment");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy contracts in dependency order
        console.log("\n--- Deploying Core Contracts ---");
        
        // 1. Deploy DailyLimitManager
        console.log("Deploying DailyLimitManager...");
        dailyLimitManager = new DailyLimitManager(cfoAddress);
        console.log("DailyLimitManager deployed at:", address(dailyLimitManager));
        
        // 2. Deploy PurchaseAgreementManager
        console.log("Deploying PurchaseAgreementManager...");
        agreementManager = new PurchaseAgreementManager(cfoAddress);
        console.log("PurchaseAgreementManager deployed at:", address(agreementManager));
        
        // 3. Deploy FraudDetection
        console.log("Deploying FraudDetection...");
        fraudDetection = new FraudDetection(cfoAddress);
        console.log("FraudDetection deployed at:", address(fraudDetection));
        
        // 4. Deploy ZKInvoiceVerifier (using the deployed Honk verifier)
        console.log("Deploying ZKInvoiceVerifier...");
        zkInvoiceVerifier = new ZKInvoiceVerifier(HONK_VERIFIER_ADDRESS);
        console.log("ZKInvoiceVerifier deployed at:", address(zkInvoiceVerifier));
        
        // 5. Deploy EnhancedInvoiceVerification
        console.log("Deploying EnhancedInvoiceVerification...");
        invoiceVerification = new EnhancedInvoiceVerification(
            address(dailyLimitManager),
            address(agreementManager),
            address(fraudDetection),
            cfoAddress,
            address(zkInvoiceVerifier)
        );
        console.log("EnhancedInvoiceVerification deployed at:", address(invoiceVerification));
        
        vm.stopBroadcast();
        
        // Post-deployment setup
        console.log("\n--- Post-deployment Setup ---");
        vm.startBroadcast(deployerPrivateKey);
        
        // Setup initial spending categories
        setupInitialCategories();
        
        // Add deployer as finance team member (for testing)
        if (deployer != cfoAddress) {
            agreementManager.addFinanceTeam(deployer);
            invoiceVerification.addFinanceTeam(deployer);
            console.log("Added deployer as finance team member");
        }
        
        vm.stopBroadcast();
        
        // Verification
        console.log("\n--- Deployment Verification ---");
        verifyDeployment();
        
        // Output deployment summary
        printDeploymentSummary();
    }
    
    function setupInitialCategories() internal {
        console.log("Setting up initial spending categories...");
        
        // Set daily limits (in wei, adjust as needed)
        dailyLimitManager.setCategoryLimit("Electronics", 50 ether);      // 50 ETH daily limit
        dailyLimitManager.setCategoryLimit("Office Supplies", 10 ether);  // 10 ETH daily limit
        dailyLimitManager.setCategoryLimit("Furniture", 30 ether);        // 30 ETH daily limit
        dailyLimitManager.setCategoryLimit("Software", 20 ether);         // 20 ETH daily limit
        dailyLimitManager.setCategoryLimit("Maintenance", 15 ether);      // 15 ETH daily limit
        
        console.log("Initial categories configured successfully");
    }
    
    function verifyDeployment() internal view {
        console.log("Verifying contract deployments...");
        
        // Check all contracts are deployed
        require(address(dailyLimitManager) != address(0), "DailyLimitManager not deployed");
        require(address(agreementManager) != address(0), "PurchaseAgreementManager not deployed");
        require(address(fraudDetection) != address(0), "FraudDetection not deployed");
        require(address(zkInvoiceVerifier) != address(0), "ZKInvoiceVerifier not deployed");
        require(address(invoiceVerification) != address(0), "EnhancedInvoiceVerification not deployed");
        
        // Verify cross-contract references
        require(
            address(invoiceVerification.dailyLimitManager()) == address(dailyLimitManager),
            "DailyLimitManager reference incorrect"
        );
        require(
            address(invoiceVerification.agreementManager()) == address(agreementManager),
            "AgreementManager reference incorrect"
        );
        require(
            address(invoiceVerification.fraudDetection()) == address(fraudDetection),
            "FraudDetection reference incorrect"
        );
        require(
            address(invoiceVerification.zkVerifier()) == address(zkInvoiceVerifier),
            "ZKVerifier reference incorrect"
        );
        
        // Verify ZK verifier reference
        require(
            zkInvoiceVerifier.honkVerifierAddress() == HONK_VERIFIER_ADDRESS,
            "Honk verifier address incorrect"
        );
        
        console.log("All verifications passed!");
    }
    
    function printDeploymentSummary() internal view {
        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("Network:", getNetworkName());
        console.log("Chain ID:", block.chainid);
        console.log("");
        console.log("Contract Addresses:");
        console.log("- DailyLimitManager:           ", address(dailyLimitManager));
        console.log("- PurchaseAgreementManager:    ", address(agreementManager));
        console.log("- FraudDetection:              ", address(fraudDetection));
        console.log("- ZKInvoiceVerifier:           ", address(zkInvoiceVerifier));
        console.log("- EnhancedInvoiceVerification: ", address(invoiceVerification));
        console.log("");
        console.log("Referenced Contracts:");
        console.log("- Honk Verifier:               ", HONK_VERIFIER_ADDRESS);
        console.log("");
        console.log("Configuration:");
        console.log("- ZK Verification Enabled:     ", invoiceVerification.zkVerificationEnabled());
        console.log("- CFO Address:                 ", invoiceVerification.cfoAddress());
        console.log("");
        console.log("Initial Categories Configured:");
        console.log("- Electronics: 50 ETH daily limit");
        console.log("- Office Supplies: 10 ETH daily limit");
        console.log("- Furniture: 30 ETH daily limit");
        console.log("- Software: 20 ETH daily limit");
        console.log("- Maintenance: 15 ETH daily limit");
        console.log("========================================");
    }
    
    function getNetworkName() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        if (chainId == 1) return "Ethereum Mainnet";
        if (chainId == 5) return "Goerli Testnet";
        if (chainId == 11155111) return "Sepolia Testnet";
        if (chainId == 4202) return "Lisk Sepolia Testnet";
        if (chainId == 31337) return "Local Network";
        return "Unknown Network";
    }
    
    // Utility function to get all contract addresses for external use
    function getContractAddresses() external view returns (
        address dailyLimit,
        address agreementManagerAddr,
        address fraudDetectionAddr,
        address invoiceVerificationAddr,
        address zkVerifierAddr,
        address honkVerifierAddr
    ) {
        return (
            address(dailyLimitManager),
            address(agreementManager),
            address(fraudDetection),
            address(invoiceVerification),
            address(zkInvoiceVerifier),
            HONK_VERIFIER_ADDRESS
        );
    }
}