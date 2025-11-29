// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

// Simplified contracts to avoid stack too deep
contract DailyLimitManager {
    struct CategoryLimit {
        string categoryName;
        uint256 dailyLimit;
        uint256 currentDaySpending;
        uint256 lastResetTimestamp;
        bool isActive;
    }

    mapping(string => CategoryLimit) public categoryLimits;
    address public cfoAddress;
    
    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "Only CFO can call this function");
        _;
    }

    constructor(address _cfoAddress) {
        cfoAddress = _cfoAddress;
    }

    function setCategoryLimit(string memory _categoryName, uint256 _dailyLimit) external onlyCFO {
        CategoryLimit storage category = categoryLimits[_categoryName];
        if (bytes(category.categoryName).length == 0) {
            category.categoryName = _categoryName;
            category.lastResetTimestamp = block.timestamp;
            category.isActive = true;
        }
        category.dailyLimit = _dailyLimit;
    }

    function checkLimitAvailable(string memory _categoryName, uint256 _amount) external view returns (bool) {
        CategoryLimit storage category = categoryLimits[_categoryName];
        require(category.isActive, "Category not active");
        return category.currentDaySpending + _amount <= category.dailyLimit;
    }

    function recordSpending(string memory _categoryName, uint256 _amount) external {
        CategoryLimit storage category = categoryLimits[_categoryName];
        require(category.isActive, "Category not active");
        category.currentDaySpending += _amount;
    }

    function getCategoryInfo(string memory _categoryName) external view returns (CategoryLimit memory) {
        return categoryLimits[_categoryName];
    }
}

contract PurchaseAgreementManager {
    struct PurchaseAgreement {
        string agreementId;
        address vendorAddress;
        string category;
        uint256 pricePerUnit;
        uint256 totalQuantity;
        uint256 remainingQuantity;
        uint256 startDate;
        uint256 endDate;
        bool vendorApproved;
        bool cfoApproved;
        bool isActive;
    }

    mapping(string => PurchaseAgreement) public agreements;
    mapping(address => bool) public isFinanceTeam;
    address public cfoAddress;

    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "Only CFO can call this function");
        _;
    }

    modifier onlyVendor(string memory _agreementId) {
        require(msg.sender == agreements[_agreementId].vendorAddress, "Only assigned vendor can call this function");
        _;
    }

    modifier onlyFinanceTeam() {
        require(isFinanceTeam[msg.sender], "Only finance team can call this function");
        _;
    }

    constructor(address _cfoAddress) {
        cfoAddress = _cfoAddress;
    }

    function addFinanceTeam(address _financeMember) external onlyCFO {
        isFinanceTeam[_financeMember] = true;
    }

    function createAgreementDraft(
        string memory _agreementId,
        address _vendorAddress,
        string memory _category,
        uint256 _pricePerUnit,
        uint256 _totalQuantity,
        uint256 _startDate,
        uint256 _endDate
    ) external onlyFinanceTeam {
        require(bytes(agreements[_agreementId].agreementId).length == 0, "Agreement ID already exists");
        
        agreements[_agreementId] = PurchaseAgreement({
            agreementId: _agreementId,
            vendorAddress: _vendorAddress,
            category: _category,
            pricePerUnit: _pricePerUnit,
            totalQuantity: _totalQuantity,
            remainingQuantity: _totalQuantity,
            startDate: _startDate,
            endDate: _endDate,
            vendorApproved: false,
            cfoApproved: false,
            isActive: false
        });
    }

    function vendorApproveAgreement(string memory _agreementId) external onlyVendor(_agreementId) {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        require(!agreement.vendorApproved, "Agreement already approved by vendor");
        agreement.vendorApproved = true;
    }

    function cfoApproveAgreement(string memory _agreementId) external onlyCFO {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        require(agreement.vendorApproved, "Vendor approval required");
        require(!agreement.cfoApproved, "Agreement already approved by CFO");
        agreement.cfoApproved = true;
        agreement.isActive = true;
    }

    function getAgreementDetails(string memory _agreementId) external view returns (PurchaseAgreement memory) {
        return agreements[_agreementId];
    }

    function updateRemainingQuantity(string memory _agreementId, uint256 _usedQuantity) external {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        require(agreement.isActive, "Agreement not active");
        require(agreement.remainingQuantity >= _usedQuantity, "Insufficient remaining quantity");
        agreement.remainingQuantity -= _usedQuantity;
    }

    function checkAgreementValidity(string memory _agreementId) external view returns (bool) {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        return agreement.isActive && 
               block.timestamp >= agreement.startDate && 
               block.timestamp <= agreement.endDate && 
               agreement.remainingQuantity > 0;
    }
}

contract FraudDetection {
    struct FraudAlert {
        uint256 alertId;
        string invoiceId;
        address submittedBy;
        string fraudType;
        uint256 expectedValue;
        uint256 submittedValue;
        bool investigated;
    }

    mapping(uint256 => FraudAlert) public fraudAlerts;
    uint256 public fraudAlertCounter;
    address public cfoAddress;

    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "Only CFO can call this function");
        _;
    }

    constructor(address _cfoAddress) {
        cfoAddress = _cfoAddress;
    }

    function recordFraudAttempt(
        string memory _invoiceId,
        address _submittedBy,
        string memory _fraudType,
        uint256 _expectedValue,
        uint256 _submittedValue
    ) external {
        fraudAlertCounter++;
        fraudAlerts[fraudAlertCounter] = FraudAlert({
            alertId: fraudAlertCounter,
            invoiceId: _invoiceId,
            submittedBy: _submittedBy,
            fraudType: _fraudType,
            expectedValue: _expectedValue,
            submittedValue: _submittedValue,
            investigated: false
        });
    }

    function getFraudAlerts() external view returns (FraudAlert[] memory) {
        FraudAlert[] memory alerts = new FraudAlert[](fraudAlertCounter);
        for (uint256 i = 1; i <= fraudAlertCounter; i++) {
            alerts[i-1] = fraudAlerts[i];
        }
        return alerts;
    }

    function markAsInvestigated(uint256 _alertId) external onlyCFO {
        require(_alertId > 0 && _alertId <= fraudAlertCounter, "Invalid alert ID");
        fraudAlerts[_alertId].investigated = true;
    }
}

contract EnhancedInvoiceVerification {
    struct Invoice {
        string invoiceId;
        string agreementId;
        uint256 quantity;
        uint256 pricePerUnit;
        uint256 totalAmount;
        string status;
        bool requiresCFOApproval;
        address submittedBy;
        bool isFraudulent;
        string fraudType;
    }

    mapping(string => Invoice) public invoices;
    DailyLimitManager public dailyLimitManager;
    PurchaseAgreementManager public agreementManager;
    FraudDetection public fraudDetection;
    address public cfoAddress;
    mapping(address => bool) public isFinanceTeam;

    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "Only CFO can call this function");
        _;
    }

    modifier onlyFinanceTeam() {
        require(isFinanceTeam[msg.sender], "Only finance team can call this function");
        _;
    }

    constructor(
        address _dailyLimitManager,
        address _agreementManager,
        address _fraudDetection,
        address _cfoAddress
    ) {
        dailyLimitManager = DailyLimitManager(_dailyLimitManager);
        agreementManager = PurchaseAgreementManager(_agreementManager);
        fraudDetection = FraudDetection(_fraudDetection);
        cfoAddress = _cfoAddress;
    }

    function addFinanceTeam(address _financeMember) external onlyCFO {
        isFinanceTeam[_financeMember] = true;
    }

    function submitInvoice(
        string memory _invoiceId,
        string memory _agreementId,
        uint256 _quantity,
        uint256 _pricePerUnit
    ) external onlyFinanceTeam {
        require(bytes(invoices[_invoiceId].invoiceId).length == 0, "Invoice ID already exists");
        
        uint256 totalAmount = _quantity * _pricePerUnit;
        
        invoices[_invoiceId] = Invoice({
            invoiceId: _invoiceId,
            agreementId: _agreementId,
            quantity: _quantity,
            pricePerUnit: _pricePerUnit,
            totalAmount: totalAmount,
            status: "PENDING",
            requiresCFOApproval: false,
            submittedBy: msg.sender,
            isFraudulent: false,
            fraudType: ""
        });
        
        _validateInvoice(_invoiceId);
    }

    function _validateInvoice(string memory _invoiceId) internal {
        Invoice storage invoice = invoices[_invoiceId];
        PurchaseAgreementManager.PurchaseAgreement memory agreement = agreementManager.getAgreementDetails(invoice.agreementId);
        
        bool priceValid = (invoice.pricePerUnit == agreement.pricePerUnit);
        bool quantityValid = (invoice.quantity <= agreement.remainingQuantity);
        bool periodValid = (block.timestamp >= agreement.startDate && block.timestamp <= agreement.endDate);
        
        if (priceValid && quantityValid && periodValid) {
            bool underLimit = dailyLimitManager.checkLimitAvailable(agreement.category, invoice.totalAmount);
            
            if (underLimit) {
                _autoApproveInvoice(_invoiceId);
            } else {
                invoice.status = "WAITING_CFO";
                invoice.requiresCFOApproval = true;
            }
        } else {
            invoice.status = "REJECTED";
            if (!priceValid && invoice.pricePerUnit > agreement.pricePerUnit) {
                fraudDetection.recordFraudAttempt(
                    _invoiceId,
                    invoice.submittedBy,
                    "PRICE_MARKUP",
                    agreement.pricePerUnit,
                    invoice.pricePerUnit
                );
                invoice.isFraudulent = true;
                invoice.fraudType = "PRICE_MARKUP";
            }
        }
    }

    function _autoApproveInvoice(string memory _invoiceId) internal {
        Invoice storage invoice = invoices[_invoiceId];
        PurchaseAgreementManager.PurchaseAgreement memory agreement = agreementManager.getAgreementDetails(invoice.agreementId);
        
        dailyLimitManager.recordSpending(agreement.category, invoice.totalAmount);
        agreementManager.updateRemainingQuantity(invoice.agreementId, invoice.quantity);
        
        invoice.status = "AUTO_APPROVED";
    }

    function cfoApproveInvoice(string memory _invoiceId) external onlyCFO {
        Invoice storage invoice = invoices[_invoiceId];
        require(keccak256(abi.encodePacked(invoice.status)) == keccak256(abi.encodePacked("WAITING_CFO")), "Invoice not waiting for CFO approval");
        
        PurchaseAgreementManager.PurchaseAgreement memory agreement = agreementManager.getAgreementDetails(invoice.agreementId);
        dailyLimitManager.recordSpending(agreement.category, invoice.totalAmount);
        agreementManager.updateRemainingQuantity(invoice.agreementId, invoice.quantity);
        
        invoice.status = "APPROVED_BY_CFO";
        invoice.requiresCFOApproval = false;
    }

    function getInvoiceStatus(string memory _invoiceId) external view returns (Invoice memory) {
        return invoices[_invoiceId];
    }
}

// SIMPLIFIED TEST CONTRACT
contract ProcurementSystemTest is Test {
    DailyLimitManager public dailyLimitManager;
    PurchaseAgreementManager public agreementManager;
    FraudDetection public fraudDetection;
    EnhancedInvoiceVerification public invoiceVerification;

    address public cfo = vm.addr(1);
    address public financeTeam = vm.addr(2);
    address public vendor = vm.addr(3);
    address public user = vm.addr(4);

    string public constant SAMPLE_AGREEMENT_ID = "AGR-001";
    string public constant SAMPLE_INVOICE_ID = "INV-001";
    string public constant CATEGORY_ELECTRONICS = "Electronics";
    
    function setUp() public {
        dailyLimitManager = new DailyLimitManager(cfo);
        agreementManager = new PurchaseAgreementManager(cfo);
        fraudDetection = new FraudDetection(cfo);
        invoiceVerification = new EnhancedInvoiceVerification(
            address(dailyLimitManager),
            address(agreementManager),
            address(fraudDetection),
            cfo
        );

        vm.prank(cfo);
        agreementManager.addFinanceTeam(financeTeam);
        
        vm.prank(cfo);
        invoiceVerification.addFinanceTeam(financeTeam);

        vm.prank(cfo);
        dailyLimitManager.setCategoryLimit(CATEGORY_ELECTRONICS, 50_000_000e18);
    }

    function test_SetCategoryLimit() public {
        vm.prank(cfo);
        dailyLimitManager.setCategoryLimit("Office Supplies", 25_000_000e18);
        
        DailyLimitManager.CategoryLimit memory category = dailyLimitManager.getCategoryInfo("Office Supplies");
        assertEq(category.categoryName, "Office Supplies");
        assertEq(category.dailyLimit, 25_000_000e18);
    }

    function test_CreateAgreement() public {
        vm.prank(financeTeam);
        agreementManager.createAgreementDraft(
            SAMPLE_AGREEMENT_ID,
            vendor,
            CATEGORY_ELECTRONICS,
            8_000_000e18,
            10,
            block.timestamp,
            block.timestamp + 30 days
        );

        PurchaseAgreementManager.PurchaseAgreement memory agreement = agreementManager.getAgreementDetails(SAMPLE_AGREEMENT_ID);
        assertEq(agreement.agreementId, SAMPLE_AGREEMENT_ID);
        assertEq(agreement.vendorAddress, vendor);
        assertEq(agreement.category, CATEGORY_ELECTRONICS);
    }

    function test_SubmitAndAutoApproveInvoice() public {
        _createAndActivateAgreement();
        
        vm.prank(financeTeam);
        invoiceVerification.submitInvoice(
            SAMPLE_INVOICE_ID,
            SAMPLE_AGREEMENT_ID,
            2,
            8_000_000e18
        );

        EnhancedInvoiceVerification.Invoice memory invoice = invoiceVerification.getInvoiceStatus(SAMPLE_INVOICE_ID);
        assertEq(invoice.invoiceId, SAMPLE_INVOICE_ID);
        assertEq(invoice.status, "AUTO_APPROVED");
    }

    function test_FraudDetection() public {
        _createAndActivateAgreement();
        
        vm.prank(financeTeam);
        invoiceVerification.submitInvoice(
            SAMPLE_INVOICE_ID,
            SAMPLE_AGREEMENT_ID,
            2,
            10_000_000e18 // Higher price than agreement
        );

        FraudDetection.FraudAlert[] memory alerts = fraudDetection.getFraudAlerts();
        assertGt(alerts.length, 0);
        assertEq(alerts[0].invoiceId, SAMPLE_INVOICE_ID);
        assertEq(alerts[0].fraudType, "PRICE_MARKUP");
    }

    function test_CFOApproveInvoice() public {
        _createAndActivateAgreement();
        
        // Use up most of the limit first
        vm.prank(address(invoiceVerification));
        dailyLimitManager.recordSpending(CATEGORY_ELECTRONICS, 45_000_000e18);
        
        vm.prank(financeTeam);
        invoiceVerification.submitInvoice(
            SAMPLE_INVOICE_ID,
            SAMPLE_AGREEMENT_ID,
            1,
            8_000_000e18
        );

        vm.prank(cfo);
        invoiceVerification.cfoApproveInvoice(SAMPLE_INVOICE_ID);

        EnhancedInvoiceVerification.Invoice memory invoice = invoiceVerification.getInvoiceStatus(SAMPLE_INVOICE_ID);
        assertEq(invoice.status, "APPROVED_BY_CFO");
    }

    function test_OnlyCFOCanSetCategoryLimit() public {
        vm.prank(user);
        vm.expectRevert("Only CFO can call this function");
        dailyLimitManager.setCategoryLimit("Test Category", 10_000_000e18);
    }

    function test_OnlyFinanceTeamCanSubmitInvoice() public {
        _createAndActivateAgreement();
        
        vm.prank(user);
        vm.expectRevert("Only finance team can call this function");
        invoiceVerification.submitInvoice(
            SAMPLE_INVOICE_ID,
            SAMPLE_AGREEMENT_ID,
            2,
            8_000_000e18
        );
    }

    function _createAndActivateAgreement() internal {
        vm.prank(financeTeam);
        agreementManager.createAgreementDraft(
            SAMPLE_AGREEMENT_ID,
            vendor,
            CATEGORY_ELECTRONICS,
            8_000_000e18,
            10,
            block.timestamp,
            block.timestamp + 30 days
        );
        
        vm.prank(vendor);
        agreementManager.vendorApproveAgreement(SAMPLE_AGREEMENT_ID);
        
        vm.prank(cfo);
        agreementManager.cfoApproveAgreement(SAMPLE_AGREEMENT_ID);
    }
}