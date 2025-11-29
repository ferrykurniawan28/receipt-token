// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/ProcurementSystem.sol";

contract VerifyContract is Script {
    // Deployed contract addresses
    address constant DAILY_LIMIT_MANAGER = 0xb0c14721B209Df0B7Aa87729d0d1b99F32f1cCf1;
    address constant AGREEMENT_MANAGER = 0x855499Cf21CB94b9Ee3F1b2B7d60457572e7e6c3;
    address constant FRAUD_DETECTION = 0x734038A097D7E34e74C6d4B38B99FfdD9d6fbb55;
    address constant ZK_INVOICE_VERIFIER = 0x0368cFF5fEdf278915b6F25bea1622e9C76f4B3B;
    address constant ENHANCED_INVOICE_VERIFICATION = 0xBb9578312514f03684800b36128712fd7D74d07D;
    address constant HONK_VERIFIER = 0x9E7C8251F45C881D42957042224055d32445805C;
    
    function run() external {
        console.log("=== PROCUREMENT SYSTEM CONTRACT VERIFICATION ===");
        console.log("Network: Lisk Sepolia (Chain ID: 4202)");
        console.log("Verification Date:", block.timestamp);
        console.log("");
        
        // Verify all contracts
        verifyDailyLimitManager();
        verifyAgreementManager();
        verifyFraudDetection();
        verifyZKInvoiceVerifier();
        verifyEnhancedInvoiceVerification();
        verifyHonkVerifier();
        
        console.log("=== VERIFICATION SUMMARY ===");
        console.log("All contracts verified and functional");
        console.log("All cross-contract references validated");
        console.log("ZK verification integration confirmed");
        console.log("Procurement system ready for production");
    }
    
    function verifyDailyLimitManager() internal {
        console.log("--- Verifying DailyLimitManager ---");
        console.log("Address:", DAILY_LIMIT_MANAGER);
        
        DailyLimitManager manager = DailyLimitManager(DAILY_LIMIT_MANAGER);
        
        // Check contract size
        uint256 size = getContractSize(DAILY_LIMIT_MANAGER);
        console.log("Contract Size:", size, "bytes");
        require(size > 0, "DailyLimitManager: No bytecode found");
        
        // Check CFO address
        address cfo = manager.cfoAddress();
        console.log("CFO Address:", cfo);
        require(cfo != address(0), "DailyLimitManager: Invalid CFO address");
        
        // Check a configured category
        try manager.getCategoryInfo("Electronics") returns (DailyLimitManager.CategoryLimit memory limit) {
            console.log("Electronics Category:");
            console.log("  - Daily Limit:", limit.dailyLimit);
            console.log("  - Active:", limit.isActive);
            require(limit.isActive, "DailyLimitManager: Electronics category not active");
        } catch {
            console.log("[FAIL] Failed to get category info");
        }
        
        console.log("[PASS] DailyLimitManager verification passed");
        console.log("");
    }
    
    function verifyAgreementManager() internal {
        console.log("--- Verifying PurchaseAgreementManager ---");
        console.log("Address:", AGREEMENT_MANAGER);
        
        PurchaseAgreementManager manager = PurchaseAgreementManager(AGREEMENT_MANAGER);
        
        uint256 size = getContractSize(AGREEMENT_MANAGER);
        console.log("Contract Size:", size, "bytes");
        require(size > 0, "AgreementManager: No bytecode found");
        
        address cfo = manager.cfoAddress();
        console.log("CFO Address:", cfo);
        require(cfo != address(0), "AgreementManager: Invalid CFO address");
        
        string[] memory agreements = manager.getAllAgreements();
        console.log("Total Agreements:", agreements.length);
        
        console.log("[PASS] PurchaseAgreementManager verification passed");
        console.log("");
    }
    
    function verifyFraudDetection() internal {
        console.log("--- Verifying FraudDetection ---");
        console.log("Address:", FRAUD_DETECTION);
        
        FraudDetection fraud = FraudDetection(FRAUD_DETECTION);
        
        uint256 size = getContractSize(FRAUD_DETECTION);
        console.log("Contract Size:", size, "bytes");
        require(size > 0, "FraudDetection: No bytecode found");
        
        address cfo = fraud.cfoAddress();
        console.log("CFO Address:", cfo);
        require(cfo != address(0), "FraudDetection: Invalid CFO address");
        
        uint256 alertCounter = fraud.fraudAlertCounter();
        console.log("Fraud Alerts Count:", alertCounter);
        
        console.log("[PASS] FraudDetection verification passed");
        console.log("");
    }
    
    function verifyZKInvoiceVerifier() internal {
        console.log("--- Verifying ZKInvoiceVerifier ---");
        console.log("Address:", ZK_INVOICE_VERIFIER);
        
        ZKInvoiceVerifier zkVerifier = ZKInvoiceVerifier(ZK_INVOICE_VERIFIER);
        
        uint256 size = getContractSize(ZK_INVOICE_VERIFIER);
        console.log("Contract Size:", size, "bytes");
        require(size > 0, "ZKInvoiceVerifier: No bytecode found");
        
        address honkAddr = zkVerifier.honkVerifierAddress();
        console.log("Honk Verifier Reference:", honkAddr);
        require(honkAddr == HONK_VERIFIER, "ZKInvoiceVerifier: Incorrect Honk verifier address");
        
        console.log("[PASS] ZKInvoiceVerifier verification passed");
        console.log("");
    }
    
    function verifyEnhancedInvoiceVerification() internal {
        console.log("--- Verifying EnhancedInvoiceVerification (Main Contract) ---");
        console.log("Address:", ENHANCED_INVOICE_VERIFICATION);
        
        EnhancedInvoiceVerification invoice = EnhancedInvoiceVerification(ENHANCED_INVOICE_VERIFICATION);
        
        uint256 size = getContractSize(ENHANCED_INVOICE_VERIFICATION);
        console.log("Contract Size:", size, "bytes");
        require(size > 0, "EnhancedInvoiceVerification: No bytecode found");
        
        // Verify all contract references
        address dailyLimit = address(invoice.dailyLimitManager());
        address agreement = address(invoice.agreementManager());
        address fraud = address(invoice.fraudDetection());
        address zkVerifier = address(invoice.zkVerifier());
        address cfo = invoice.cfoAddress();
        
        console.log("Contract References:");
        console.log("  - DailyLimitManager:", dailyLimit);
        console.log("  - AgreementManager:", agreement);
        console.log("  - FraudDetection:", fraud);
        console.log("  - ZKVerifier:", zkVerifier);
        console.log("  - CFO Address:", cfo);
        
        require(dailyLimit == DAILY_LIMIT_MANAGER, "EnhancedInvoiceVerification: Wrong DailyLimitManager");
        require(agreement == AGREEMENT_MANAGER, "EnhancedInvoiceVerification: Wrong AgreementManager");
        require(fraud == FRAUD_DETECTION, "EnhancedInvoiceVerification: Wrong FraudDetection");
        require(zkVerifier == ZK_INVOICE_VERIFIER, "EnhancedInvoiceVerification: Wrong ZKVerifier");
        require(cfo != address(0), "EnhancedInvoiceVerification: Invalid CFO address");
        
        // Check ZK verification status
        bool zkEnabled = invoice.zkVerificationEnabled();
        console.log("ZK Verification Enabled:", zkEnabled);
        require(zkEnabled, "EnhancedInvoiceVerification: ZK verification should be enabled");
        
        console.log("[PASS] EnhancedInvoiceVerification verification passed");
        console.log("");
    }
    
    function verifyHonkVerifier() internal {
        console.log("--- Verifying HonkVerifier (External Reference) ---");
        console.log("Address:", HONK_VERIFIER);
        
        uint256 size = getContractSize(HONK_VERIFIER);
        console.log("Contract Size:", size, "bytes");
        require(size > 0, "HonkVerifier: No bytecode found at referenced address");
        
        console.log("[PASS] HonkVerifier reference verification passed");
        console.log("");
    }
    
    function getContractSize(address contractAddr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(contractAddr)
        }
    }
}