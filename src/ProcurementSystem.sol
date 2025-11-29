// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./MockVerifier.sol"; // Import verifier interface

contract DailyLimitManager {
    struct CategoryLimit {
        string categoryName;
        uint256 dailyLimit;
        uint256 currentDaySpending;
        uint256 lastResetTimestamp;
        bool isActive;
    }

    mapping(string => CategoryLimit) public categoryLimits;
    mapping(uint256 => mapping(string => uint256)) public dailySpendingHistory;
    address public cfoAddress;
    
    event DailyLimitSet(string category, uint256 limit, address setBy);
    event DailyLimitExceeded(string category, uint256 attemptedAmount, uint256 limit);
    event SpendingRecorded(string category, uint256 amount, uint256 currentSpending);
    event DailyLimitReset(string category, uint256 newSpending);

    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "Only CFO can call this function");
        _;
    }

    constructor(address _cfoAddress) {
        cfoAddress = _cfoAddress;
    }

    function setCategoryLimit(
        string memory _categoryName,
        uint256 _dailyLimit
    ) external onlyCFO {
        CategoryLimit storage category = categoryLimits[_categoryName];
        
        if (bytes(category.categoryName).length == 0) {
            // New category
            category.categoryName = _categoryName;
            category.lastResetTimestamp = block.timestamp;
            category.isActive = true;
        }
        
        category.dailyLimit = _dailyLimit;
        
        emit DailyLimitSet(_categoryName, _dailyLimit, msg.sender);
    }

    function getCurrentDaySpending(
        string memory _categoryName
    ) external returns (uint256) {
        CategoryLimit storage category = categoryLimits[_categoryName];
        require(category.isActive, "Category not active");
        
        _resetIfNeeded(category);
        return category.currentDaySpending;
    }

    function checkLimitAvailable(
        string memory _categoryName,
        uint256 _amount
    ) external returns (bool) {
        CategoryLimit storage category = categoryLimits[_categoryName];
        require(category.isActive, "Category not active");
        
        _resetIfNeeded(category);
        
        bool isUnderLimit = category.currentDaySpending + _amount <= category.dailyLimit;
        
        if (!isUnderLimit) {
            emit DailyLimitExceeded(_categoryName, _amount, category.dailyLimit);
        }
        
        return isUnderLimit;
    }

    function recordSpending(
        string memory _categoryName,
        uint256 _amount
    ) external {
        CategoryLimit storage category = categoryLimits[_categoryName];
        require(category.isActive, "Category not active");
        
        _resetIfNeeded(category);
        
        category.currentDaySpending += _amount;
        dailySpendingHistory[block.timestamp / 1 days][_categoryName] = category.currentDaySpending;
        
        emit SpendingRecorded(_categoryName, _amount, category.currentDaySpending);
    }

    function resetDailyLimit(string memory _categoryName) external {
        CategoryLimit storage category = categoryLimits[_categoryName];
        require(category.isActive, "Category not active");
        
        _resetIfNeeded(category);
    }

    function _resetIfNeeded(CategoryLimit storage _category) internal {
        uint256 currentDay = block.timestamp / 1 days;
        uint256 lastResetDay = _category.lastResetTimestamp / 1 days;
        
        if (currentDay > lastResetDay) {
            _category.currentDaySpending = 0;
            _category.lastResetTimestamp = block.timestamp;
            
            emit DailyLimitReset(_category.categoryName, _category.currentDaySpending);
        }
    }

    function getCategoryInfo(
        string memory _categoryName
    ) external view returns (CategoryLimit memory) {
        return categoryLimits[_categoryName];
    }
}

contract PurchaseAgreementManager {
    struct PaymentMilestone {
        uint256 milestoneNumber;
        uint256 quantity;
        uint256 amount;
        bool isCompleted;
    }

    struct PurchaseAgreement {
        string agreementId;
        address vendorAddress;
        string vendorName;
        string category;
        string itemName;
        string specifications;
        uint256 pricePerUnit;
        uint256 totalQuantity;
        uint256 remainingQuantity;
        uint256 startDate;
        uint256 endDate;
        string paymentTerms;
        PaymentMilestone[] milestones;
        string contractDocumentHash;
        bool vendorApproved;
        uint256 vendorApprovedAt;
        address vendorApprovedBy;
        bool cfoApproved;
        uint256 cfoApprovedAt;
        address cfoApprovedBy;
        bool isActive;
        uint256 createdAt;
        address createdBy;
    }

    mapping(string => PurchaseAgreement) public agreements;
    string[] public agreementIds;
    mapping(address => string[]) public vendorAgreements;
    
    address public cfoAddress;
    
    enum AgreementStatus { DRAFT, VENDOR_APPROVED, CFO_APPROVED, ACTIVE, REJECTED, NEGOTIATING }

    event AgreementCreated(string agreementId, address createdBy);
    event VendorApproved(string agreementId, address vendor);
    event VendorRejected(string agreementId, string reason);
    event VendorNegotiation(string agreementId, uint256 proposedPrice, string reason); // Fixed: added 'event'
    event CFOApproved(string agreementId, address cfo);
    event CFORejected(string agreementId, string reason);
    event AgreementActive(string agreementId);
    event QuantityUpdated(string agreementId, uint256 usedQuantity, uint256 remaining);

    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "Only CFO can call this function");
        _;
    }

    modifier onlyVendor(string memory _agreementId) {
        require(
            msg.sender == agreements[_agreementId].vendorAddress,
            "Only assigned vendor can call this function"
        );
        _;
    }

    modifier onlyFinanceTeam() {
        require(isFinanceTeam[msg.sender], "Only finance team can call this function");
        _;
    }

    mapping(address => bool) public isFinanceTeam;

    constructor(address _cfoAddress) {
        cfoAddress = _cfoAddress;
    }

    function addFinanceTeam(address _financeMember) external onlyCFO {
        isFinanceTeam[_financeMember] = true;
    }

    function removeFinanceTeam(address _financeMember) external onlyCFO {
        isFinanceTeam[_financeMember] = false;
    }

    function createAgreementDraft(
        string memory _agreementId,
        address _vendorAddress,
        string memory _vendorName,
        string memory _category,
        string memory _itemName,
        string memory _specifications,
        uint256 _pricePerUnit,
        uint256 _totalQuantity,
        uint256 _startDate,
        uint256 _endDate,
        string memory _paymentTerms,
        PaymentMilestone[] memory _milestones,
        string memory _contractDocumentHash
    ) external onlyFinanceTeam {
        require(bytes(agreements[_agreementId].agreementId).length == 0, "Agreement ID already exists");
        
        PurchaseAgreement storage agreement = agreements[_agreementId];
        agreement.agreementId = _agreementId;
        agreement.vendorAddress = _vendorAddress;
        agreement.vendorName = _vendorName;
        agreement.category = _category;
        agreement.itemName = _itemName;
        agreement.specifications = _specifications;
        agreement.pricePerUnit = _pricePerUnit;
        agreement.totalQuantity = _totalQuantity;
        agreement.remainingQuantity = _totalQuantity;
        agreement.startDate = _startDate;
        agreement.endDate = _endDate;
        agreement.paymentTerms = _paymentTerms;
        agreement.contractDocumentHash = _contractDocumentHash;
        agreement.createdAt = block.timestamp;
        agreement.createdBy = msg.sender;
        
        // Add milestones if provided
        for (uint i = 0; i < _milestones.length; i++) {
            agreement.milestones.push(_milestones[i]);
        }
        
        agreementIds.push(_agreementId);
        vendorAgreements[_vendorAddress].push(_agreementId);
        
        emit AgreementCreated(_agreementId, msg.sender);
    }

    function vendorApproveAgreement(
        string memory _agreementId
    ) external onlyVendor(_agreementId) {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        require(!agreement.vendorApproved, "Agreement already approved by vendor");
        require(!agreement.isActive, "Agreement already active");
        
        agreement.vendorApproved = true;
        agreement.vendorApprovedAt = block.timestamp;
        agreement.vendorApprovedBy = msg.sender;
        
        emit VendorApproved(_agreementId, msg.sender);
    }

    function vendorRejectAgreement(
        string memory _agreementId,
        string memory _rejectionReason
    ) external onlyVendor(_agreementId) {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        require(!agreement.vendorApproved, "Agreement already approved");
        
        emit VendorRejected(_agreementId, _rejectionReason);
    }

    function vendorNegotiateAgreement(
        string memory _agreementId,
        uint256 _proposedPrice,
        string memory _negotiationReason
    ) external onlyVendor(_agreementId) {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        require(!agreement.vendorApproved, "Agreement already approved");
        
        emit VendorNegotiation(_agreementId, _proposedPrice, _negotiationReason); // Fixed: correct event name
    }

    function cfoApproveAgreement(
        string memory _agreementId
    ) external onlyCFO {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        require(agreement.vendorApproved, "Vendor approval required");
        require(!agreement.cfoApproved, "Agreement already approved by CFO");
        require(block.timestamp >= agreement.startDate, "Agreement not started yet");
        require(block.timestamp <= agreement.endDate, "Agreement expired");
        
        agreement.cfoApproved = true;
        agreement.cfoApprovedAt = block.timestamp;
        agreement.cfoApprovedBy = msg.sender;
        agreement.isActive = true;
        
        emit CFOApproved(_agreementId, msg.sender);
        emit AgreementActive(_agreementId);
    }

    function cfoRejectAgreement(
        string memory _agreementId,
        string memory _rejectionReason
    ) external onlyCFO {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        require(!agreement.cfoApproved, "Agreement already approved");
        
        emit CFORejected(_agreementId, _rejectionReason);
    }

    function getAgreementDetails(
        string memory _agreementId
    ) external view returns (PurchaseAgreement memory) {
        return agreements[_agreementId];
    }

    function updateRemainingQuantity(
        string memory _agreementId,
        uint256 _usedQuantity
    ) external {
        // This should be called only by InvoiceVerification contract
        PurchaseAgreement storage agreement = agreements[_agreementId];
        require(agreement.isActive, "Agreement not active");
        require(agreement.remainingQuantity >= _usedQuantity, "Insufficient remaining quantity");
        
        agreement.remainingQuantity -= _usedQuantity;
        
        emit QuantityUpdated(_agreementId, _usedQuantity, agreement.remainingQuantity);
    }

    function checkAgreementValidity(
        string memory _agreementId
    ) external view returns (bool) {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        
        return (
            agreement.isActive &&
            block.timestamp >= agreement.startDate &&
            block.timestamp <= agreement.endDate &&
            agreement.remainingQuantity > 0
        );
    }

    function getAgreementStatus(
        string memory _agreementId
    ) external view returns (AgreementStatus) {
        PurchaseAgreement storage agreement = agreements[_agreementId];
        
        if (!agreement.vendorApproved && !agreement.cfoApproved) return AgreementStatus.DRAFT;
        if (agreement.vendorApproved && !agreement.cfoApproved) return AgreementStatus.VENDOR_APPROVED;
        if (agreement.vendorApproved && agreement.cfoApproved && agreement.isActive) return AgreementStatus.ACTIVE;
        if (agreement.isActive) return AgreementStatus.CFO_APPROVED;
        
        return AgreementStatus.DRAFT;
    }

    function getAllAgreements() external view returns (string[] memory) {
        return agreementIds;
    }

    function getVendorAgreements(
        address _vendor
    ) external view returns (string[] memory) {
        return vendorAgreements[_vendor];
    }
}

contract FraudDetection {
    struct FraudAlert {
        uint256 alertId;
        string invoiceId;
        address submittedBy;
        uint256 timestamp;
        string fraudType;
        uint256 expectedValue;
        uint256 submittedValue;
        uint256 difference;
        string agreementId;
        string description;
        bool investigated;
        string investigationNotes;
    }

    mapping(uint256 => FraudAlert) public fraudAlerts;
    uint256 public fraudAlertCounter;
    mapping(address => uint256[]) public userFraudHistory;
    
    address public cfoAddress;
    
    event FraudDetected(uint256 alertId, string invoiceId, address submittedBy, string fraudType);
    event FraudInvestigated(uint256 alertId, string investigationNotes);

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
        uint256 _submittedValue,
        string memory _agreementId
    ) external {
        fraudAlertCounter++;
        
        FraudAlert storage alert = fraudAlerts[fraudAlertCounter];
        alert.alertId = fraudAlertCounter;
        alert.invoiceId = _invoiceId;
        alert.submittedBy = _submittedBy;
        alert.timestamp = block.timestamp;
        alert.fraudType = _fraudType;
        alert.expectedValue = _expectedValue;
        alert.submittedValue = _submittedValue;
        alert.difference = _submittedValue > _expectedValue ? 
            _submittedValue - _expectedValue : _expectedValue - _submittedValue;
        alert.agreementId = _agreementId;
        alert.description = string(abi.encodePacked(
            _fraudType,
            " detected. Expected: ",
            uint2str(_expectedValue),
            ", Submitted: ",
            uint2str(_submittedValue)
        ));
        
        userFraudHistory[_submittedBy].push(fraudAlertCounter);
        
        emit FraudDetected(fraudAlertCounter, _invoiceId, _submittedBy, _fraudType);
    }

    function getFraudAlerts() external view returns (FraudAlert[] memory) {
        FraudAlert[] memory alerts = new FraudAlert[](fraudAlertCounter);
        
        for (uint256 i = 1; i <= fraudAlertCounter; i++) {
            alerts[i-1] = fraudAlerts[i];
        }
        
        return alerts;
    }

    function markAsInvestigated(
        uint256 _alertId,
        string memory _investigationNotes
    ) external onlyCFO {
        require(_alertId > 0 && _alertId <= fraudAlertCounter, "Invalid alert ID");
        
        FraudAlert storage alert = fraudAlerts[_alertId];
        alert.investigated = true;
        alert.investigationNotes = _investigationNotes;
        
        emit FraudInvestigated(_alertId, _investigationNotes);
    }

    function getUserFraudHistory(
        address _user
    ) external view returns (FraudAlert[] memory) {
        uint256[] memory userAlerts = userFraudHistory[_user];
        FraudAlert[] memory alerts = new FraudAlert[](userAlerts.length);
        
        for (uint256 i = 0; i < userAlerts.length; i++) {
            alerts[i] = fraudAlerts[userAlerts[i]];
        }
        
        return alerts;
    }

    // Helper function
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

contract ZKInvoiceVerifier {
    // Alamat verifier yang sudah deployed
    address public immutable honkVerifierAddress;
    
    // Mapping untuk menyimpan proof hash dan status
    mapping(bytes32 => bool) public proofVerified;
    mapping(string => bytes32) public invoiceProofHash; // invoiceId => proofHash
    
    // Events
    event ProofVerified(bytes32 proofHash, string invoiceId, uint256 timestamp);
    event ProofVerificationFailed(bytes32 proofHash, string invoiceId, string reason);
    
    constructor(address _honkVerifierAddress) {
        honkVerifierAddress = _honkVerifierAddress;
    }
    
    /**
     * @notice Verifikasi ZK proof untuk invoice
     * @param _invoiceId ID invoice yang diverifikasi
     * @param _proof Bytes proof dari Honk
     * @param _publicInputs Public inputs untuk verifikasi
     */
    function verifyInvoiceProof(
        string memory _invoiceId,
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external returns (bool) {
        bytes32 proofHash = keccak256(_proof);
        
        // Cek apakah proof sudah pernah diverifikasi
        if (proofVerified[proofHash]) {
            emit ProofVerified(proofHash, _invoiceId, block.timestamp);
            return true;
        }
        
        try IHonkVerifier(honkVerifierAddress).verify(_proof, _publicInputs) returns (bool success) {
            if (success) {
                proofVerified[proofHash] = true;
                invoiceProofHash[_invoiceId] = proofHash;
                
                emit ProofVerified(proofHash, _invoiceId, block.timestamp);
                return true;
            } else {
                emit ProofVerificationFailed(proofHash, _invoiceId, "Proof verification failed");
                return false;
            }
        } catch Error(string memory reason) {
            emit ProofVerificationFailed(proofHash, _invoiceId, reason);
            return false;
        } catch {
            emit ProofVerificationFailed(proofHash, _invoiceId, "Unknown error");
            return false;
        }
    }
    
    /**
     * @notice Cek status verifikasi proof untuk invoice
     * @param _invoiceId ID invoice yang dicek
     */
    function isInvoiceVerified(string memory _invoiceId) external view returns (bool) {
        bytes32 hash = invoiceProofHash[_invoiceId];
        return hash != bytes32(0) && proofVerified[hash];
    }
    
    /**
     * @notice Dapatkan proof hash untuk invoice
     * @param _invoiceId ID invoice
     */
    function getInvoiceProofHash(string memory _invoiceId) external view returns (bytes32) {
        return invoiceProofHash[_invoiceId];
    }
}

contract EnhancedInvoiceVerification {
    struct Invoice {
        string invoiceId;
        string agreementId;
        string invoiceNumber;
        uint256 invoiceDate;
        uint256 deliveryDate;
        uint256 quantity;
        uint256 pricePerUnit;
        uint256 totalAmount;
        uint256 milestoneNumber;
        string invoiceScanHash;
        string deliveryNoteHash;
        string[] photoHashes;
        bool priceValid;
        bool quantityValid;
        bool periodValid;
        bool milestoneValid;
        string validationFailReason;
        string status;
        bool requiresCFOApproval;
        address cfoApprovedBy;
        uint256 cfoApprovedAt;
        string cfoApprovalReason;
        string cfoRejectionReason;
        bytes32 zkProofHash;
        uint256 submittedAt;
        address submittedBy;
        bool isFraudulent;
        string fraudType;
    }

    mapping(string => Invoice) public invoices;
    string[] public invoiceIds;
    mapping(string => string[]) public agreementInvoices;
    
    DailyLimitManager public dailyLimitManager;
    PurchaseAgreementManager public agreementManager;
    FraudDetection public fraudDetection;
    ZKInvoiceVerifier public zkVerifier;
    address public cfoAddress;
    
    mapping(address => bool) public isFinanceTeam;
    bool public zkVerificationEnabled;

    enum InvoiceStatus { 
        PENDING, 
        AUTO_APPROVED, 
        WAITING_CFO, 
        APPROVED_BY_CFO, 
        REJECTED,
        AUTO_APPROVED_ZK,
        WAITING_CFO_ZK,
        REJECTED_ZK
    }

    event InvoiceSubmitted(string invoiceId, string agreementId);
    event InvoiceAutoApproved(string invoiceId);
    event InvoiceNeedsCFOApproval(string invoiceId, uint256 amount);
    event InvoiceApprovedByCFO(string invoiceId, address cfo);
    event InvoiceRejected(string invoiceId, string reason);
    event InvoiceValidated(string invoiceId, bool isValid, string[] errors);
    event ZKProofGenerated(string invoiceId, bytes32 proofHash);
    event ZKVerificationCompleted(string invoiceId, bool success);
    event ZKVerificationToggled(bool enabled);

    modifier onlyCFO() {
        require(msg.sender == cfoAddress, "Only CFO can call this function");
        _;
    }

    modifier onlyFinanceTeam() {
        require(isFinanceTeam[msg.sender], "Only finance team can call this function");
        _;
    }

    modifier onlyWhenZKEnabled() {
        require(zkVerificationEnabled, "ZK verification is disabled");
        _;
    }

    constructor(
        address _dailyLimitManager,
        address _agreementManager,
        address _fraudDetection,
        address _cfoAddress,
        address _zkVerifier
    ) {
        dailyLimitManager = DailyLimitManager(_dailyLimitManager);
        agreementManager = PurchaseAgreementManager(_agreementManager);
        fraudDetection = FraudDetection(_fraudDetection);
        cfoAddress = _cfoAddress;
        zkVerifier = ZKInvoiceVerifier(_zkVerifier);
        zkVerificationEnabled = true;
    }

    function addFinanceTeam(address _financeMember) external onlyCFO {
        isFinanceTeam[_financeMember] = true;
    }

    function removeFinanceTeam(address _financeMember) external onlyCFO {
        isFinanceTeam[_financeMember] = false;
    }

    /**
     * @notice Submit invoice dengan ZK proof
     */
    function submitInvoiceWithZK(
        string memory _invoiceId,
        string memory _agreementId,
        string memory _invoiceNumber,
        uint256 _invoiceDate,
        uint256 _deliveryDate,
        uint256 _quantity,
        uint256 _pricePerUnit,
        uint256 _milestoneNumber,
        string memory _invoiceScanHash,
        string memory _deliveryNoteHash,
        string[] memory _photoHashes,
        bytes calldata _zkProof,
        bytes32[] calldata _publicInputs
    ) external onlyFinanceTeam onlyWhenZKEnabled {
        require(bytes(invoices[_invoiceId].invoiceId).length == 0, "Invoice ID already exists");
        
        uint256 totalAmount = _quantity * _pricePerUnit;
        
        Invoice storage invoice = invoices[_invoiceId];
        invoice.invoiceId = _invoiceId;
        invoice.agreementId = _agreementId;
        invoice.invoiceNumber = _invoiceNumber;
        invoice.invoiceDate = _invoiceDate;
        invoice.deliveryDate = _deliveryDate;
        invoice.quantity = _quantity;
        invoice.pricePerUnit = _pricePerUnit;
        invoice.totalAmount = totalAmount;
        invoice.milestoneNumber = _milestoneNumber;
        invoice.invoiceScanHash = _invoiceScanHash;
        invoice.deliveryNoteHash = _deliveryNoteHash;
        invoice.photoHashes = _photoHashes;
        invoice.status = "PENDING";
        invoice.submittedAt = block.timestamp;
        invoice.submittedBy = msg.sender;
        
        invoiceIds.push(_invoiceId);
        agreementInvoices[_agreementId].push(_invoiceId);
        
        emit InvoiceSubmitted(_invoiceId, _agreementId);
        
        // Verifikasi ZK proof jika provided
        if (_zkProof.length > 0) {
            _verifyZKProof(_invoiceId, _zkProof, _publicInputs);
        } else {
            // Auto-validate tanpa ZK
            validateInvoice(_invoiceId);
        }
    }

    /**
     * @notice Submit invoice tanpa ZK proof (traditional)
     */
    function submitInvoice(
        string memory _invoiceId,
        string memory _agreementId,
        string memory _invoiceNumber,
        uint256 _invoiceDate,
        uint256 _deliveryDate,
        uint256 _quantity,
        uint256 _pricePerUnit,
        uint256 _milestoneNumber,
        string memory _invoiceScanHash,
        string memory _deliveryNoteHash,
        string[] memory _photoHashes
    ) external onlyFinanceTeam {
        require(bytes(invoices[_invoiceId].invoiceId).length == 0, "Invoice ID already exists");
        
        uint256 totalAmount = _quantity * _pricePerUnit;
        
        Invoice storage invoice = invoices[_invoiceId];
        invoice.invoiceId = _invoiceId;
        invoice.agreementId = _agreementId;
        invoice.invoiceNumber = _invoiceNumber;
        invoice.invoiceDate = _invoiceDate;
        invoice.deliveryDate = _deliveryDate;
        invoice.quantity = _quantity;
        invoice.pricePerUnit = _pricePerUnit;
        invoice.totalAmount = totalAmount;
        invoice.milestoneNumber = _milestoneNumber;
        invoice.invoiceScanHash = _invoiceScanHash;
        invoice.deliveryNoteHash = _deliveryNoteHash;
        invoice.photoHashes = _photoHashes;
        invoice.status = "PENDING";
        invoice.submittedAt = block.timestamp;
        invoice.submittedBy = msg.sender;
        
        invoiceIds.push(_invoiceId);
        agreementInvoices[_agreementId].push(_invoiceId);
        
        emit InvoiceSubmitted(_invoiceId, _agreementId);
        
        // Auto-validate
        validateInvoice(_invoiceId);
    }

    function validateInvoice(
        string memory _invoiceId
    ) public returns (bool, string[] memory) {
        Invoice storage invoice = invoices[_invoiceId];
        require(bytes(invoice.invoiceId).length > 0, "Invoice not found");
        
        string[] memory errors = new string[](4);
        uint256 errorCount = 0;
        
        // Get agreement details
        PurchaseAgreementManager.PurchaseAgreement memory agreement = 
            agreementManager.getAgreementDetails(invoice.agreementId);
        
        // CHECK 1: Price match
        if (invoice.pricePerUnit != agreement.pricePerUnit) {
            invoice.priceValid = false;
            errors[errorCount] = string(abi.encodePacked(
                "Price mismatch. Expected: ", 
                uint2str(agreement.pricePerUnit), 
                ", Got: ", 
                uint2str(invoice.pricePerUnit)
            ));
            errorCount++;
            
            // Record fraud attempt for significant price differences
            if (invoice.pricePerUnit > agreement.pricePerUnit) {
                fraudDetection.recordFraudAttempt(
                    _invoiceId,
                    invoice.submittedBy,
                    "PRICE_MARKUP",
                    agreement.pricePerUnit,
                    invoice.pricePerUnit,
                    invoice.agreementId
                );
                invoice.isFraudulent = true;
                invoice.fraudType = "PRICE_MARKUP";
            }
        } else {
            invoice.priceValid = true;
        }
        
        // CHECK 2: Quantity available
        if (invoice.quantity > agreement.remainingQuantity) {
            invoice.quantityValid = false;
            errors[errorCount] = string(abi.encodePacked(
                "Quantity exceeds remaining. Available: ",
                uint2str(agreement.remainingQuantity),
                ", Requested: ",
                uint2str(invoice.quantity)
            ));
            errorCount++;
            
            fraudDetection.recordFraudAttempt(
                _invoiceId,
                invoice.submittedBy,
                "QUANTITY_EXCESS",
                agreement.remainingQuantity,
                invoice.quantity,
                invoice.agreementId
            );
            invoice.isFraudulent = true;
            invoice.fraudType = "QUANTITY_EXCESS";
        } else {
            invoice.quantityValid = true;
        }
        
        // CHECK 3: Contract period valid
        if (block.timestamp < agreement.startDate || block.timestamp > agreement.endDate) {
            invoice.periodValid = false;
            errors[errorCount] = "Agreement period expired or not started";
            errorCount++;
            
            fraudDetection.recordFraudAttempt(
                _invoiceId,
                invoice.submittedBy,
                "EXPIRED_CONTRACT",
                agreement.endDate,
                block.timestamp,
                invoice.agreementId
            );
            invoice.isFraudulent = true;
            invoice.fraudType = "EXPIRED_CONTRACT";
        } else {
            invoice.periodValid = true;
        }
        
        // CHECK 4: Milestone validation (if installment)
        if (keccak256(abi.encodePacked(agreement.paymentTerms)) == keccak256(abi.encodePacked("INSTALLMENT"))) {
            if (invoice.milestoneNumber > 0) {
                bool milestoneValid = false;
                for (uint i = 0; i < agreement.milestones.length; i++) {
                    if (agreement.milestones[i].milestoneNumber == invoice.milestoneNumber &&
                        !agreement.milestones[i].isCompleted) {
                        milestoneValid = true;
                        break;
                    }
                }
                
                if (!milestoneValid) {
                    invoice.milestoneValid = false;
                    errors[errorCount] = "Invalid or completed milestone";
                    errorCount++;
                } else {
                    invoice.milestoneValid = true;
                }
            }
        } else {
            invoice.milestoneValid = true;
        }
        
        bool isValid = (errorCount == 0);
        
        if (isValid) {
            // Check daily limit
            bool requiresCFO = checkDailyLimit(_invoiceId);
            
            if (!requiresCFO) {
                autoApproveInvoice(_invoiceId);
            } else {
                invoice.status = "WAITING_CFO";
                invoice.requiresCFOApproval = true;
                emit InvoiceNeedsCFOApproval(_invoiceId, invoice.totalAmount);
            }
        } else {
            invoice.status = "REJECTED";
            invoice.validationFailReason = concatenateErrors(errors, errorCount);
        }
        
        emit InvoiceValidated(_invoiceId, isValid, errors);
        
        return (isValid, errors);
    }

    function _verifyZKProof(
        string memory _invoiceId,
        bytes calldata _zkProof,
        bytes32[] calldata _publicInputs
    ) internal returns (bool) {
        bool success = zkVerifier.verifyInvoiceProof(_invoiceId, _zkProof, _publicInputs);
        
        if (success) {
            // Update invoice status berdasarkan ZK verification
            Invoice storage invoice = invoices[_invoiceId];
            invoice.zkProofHash = keccak256(_zkProof);
            
            // Jika ZK verification sukses dan semua validasi lain pass, bisa auto-approve
            if (keccak256(abi.encodePacked(invoice.status)) == keccak256(abi.encodePacked("PENDING"))) {
                _processZKVerifiedInvoice(_invoiceId);
            }
        }
        
        emit ZKVerificationCompleted(_invoiceId, success);
        return success;
    }

    function _processZKVerifiedInvoice(string memory _invoiceId) internal {
        Invoice storage invoice = invoices[_invoiceId];
        
        // Validasi dasar masih diperlukan
        (bool isValid, string[] memory errors) = validateInvoice(_invoiceId);
        
        if (isValid) {
            bool requiresCFO = checkDailyLimit(_invoiceId);
            
            if (!requiresCFO) {
                autoApproveInvoice(_invoiceId);
                invoice.status = "AUTO_APPROVED_ZK";
            } else {
                invoice.status = "WAITING_CFO_ZK";
                invoice.requiresCFOApproval = true;
                emit InvoiceNeedsCFOApproval(_invoiceId, invoice.totalAmount);
            }
        } else {
            invoice.status = "REJECTED_ZK";
            invoice.validationFailReason = concatenateErrors(errors, errors.length);
        }
    }

    function verifyInvoiceZKProof(
        string memory _invoiceId,
        bytes calldata _zkProof,
        bytes32[] calldata _publicInputs
    ) external onlyWhenZKEnabled returns (bool) {
        require(bytes(invoices[_invoiceId].invoiceId).length > 0, "Invoice not found");
        return _verifyZKProof(_invoiceId, _zkProof, _publicInputs);
    }

    function checkDailyLimit(
        string memory _invoiceId
    ) internal returns (bool) {
        Invoice storage invoice = invoices[_invoiceId];
        PurchaseAgreementManager.PurchaseAgreement memory agreement = 
            agreementManager.getAgreementDetails(invoice.agreementId);
        
        bool underLimit = dailyLimitManager.checkLimitAvailable(
            agreement.category,
            invoice.totalAmount
        );
        
        return !underLimit;
    }

    function autoApproveInvoice(
        string memory _invoiceId
    ) internal {
        Invoice storage invoice = invoices[_invoiceId];
        
        // Record spending
        PurchaseAgreementManager.PurchaseAgreement memory agreement = 
            agreementManager.getAgreementDetails(invoice.agreementId);
        
        dailyLimitManager.recordSpending(agreement.category, invoice.totalAmount);
        
        // Update remaining quantity
        agreementManager.updateRemainingQuantity(invoice.agreementId, invoice.quantity);
        
        // Generate ZK proof
        invoice.zkProofHash = generateZKProof(_invoiceId);
        
        if (keccak256(abi.encodePacked(invoice.status)) == keccak256(abi.encodePacked("PENDING"))) {
            invoice.status = "AUTO_APPROVED";
        }
        invoice.requiresCFOApproval = false;
        
        emit InvoiceAutoApproved(_invoiceId);
    }

    function cfoApproveInvoice(
        string memory _invoiceId,
        string memory _approvalReason
    ) external onlyCFO {
        Invoice storage invoice = invoices[_invoiceId];
        require(
            keccak256(abi.encodePacked(invoice.status)) == keccak256(abi.encodePacked("WAITING_CFO")) ||
            keccak256(abi.encodePacked(invoice.status)) == keccak256(abi.encodePacked("WAITING_CFO_ZK")),
            "Invoice not waiting for CFO approval"
        );
        
        // Record spending
        PurchaseAgreementManager.PurchaseAgreement memory agreement = 
            agreementManager.getAgreementDetails(invoice.agreementId);
        
        dailyLimitManager.recordSpending(agreement.category, invoice.totalAmount);
        
        // Update remaining quantity
        agreementManager.updateRemainingQuantity(invoice.agreementId, invoice.quantity);
        
        // Generate ZK proof
        invoice.zkProofHash = generateZKProof(_invoiceId);
        
        invoice.status = "APPROVED_BY_CFO";
        invoice.cfoApprovedBy = msg.sender;
        invoice.cfoApprovedAt = block.timestamp;
        invoice.cfoApprovalReason = _approvalReason;
        invoice.requiresCFOApproval = false;
        
        emit InvoiceApprovedByCFO(_invoiceId, msg.sender);
    }

    function cfoRejectInvoice(
        string memory _invoiceId,
        string memory _rejectionReason
    ) external onlyCFO {
        Invoice storage invoice = invoices[_invoiceId];
        require(
            keccak256(abi.encodePacked(invoice.status)) == keccak256(abi.encodePacked("WAITING_CFO")) ||
            keccak256(abi.encodePacked(invoice.status)) == keccak256(abi.encodePacked("WAITING_CFO_ZK")),
            "Invoice not waiting for CFO approval"
        );
        
        invoice.status = "REJECTED";
        invoice.cfoRejectionReason = _rejectionReason;
        
        emit InvoiceRejected(_invoiceId, _rejectionReason);
    }

    function generateZKProof(
        string memory _invoiceId
    ) internal returns (bytes32) {
        Invoice storage invoice = invoices[_invoiceId];
        
        bytes32 proofHash = keccak256(abi.encodePacked(
            _invoiceId,
            invoice.agreementId,
            invoice.totalAmount,
            block.timestamp
        ));
        
        emit ZKProofGenerated(_invoiceId, proofHash);
        return proofHash;
    }

    function toggleZKVerification(bool _enabled) external onlyCFO {
        zkVerificationEnabled = _enabled;
        emit ZKVerificationToggled(_enabled);
    }

    function isInvoiceZKVerified(string memory _invoiceId) external view returns (bool) {
        return zkVerifier.isInvoiceVerified(_invoiceId);
    }

    function getInvoiceStatus(
        string memory _invoiceId
    ) external view returns (Invoice memory) {
        return invoices[_invoiceId];
    }

    function getAgreementInvoices(
        string memory _agreementId
    ) external view returns (string[] memory) {
        return agreementInvoices[_agreementId];
    }

    // Helper functions
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function concatenateErrors(
        string[] memory _errors, 
        uint256 _errorCount
    ) internal pure returns (string memory) {
        string memory result = "";
        for (uint i = 0; i < _errorCount; i++) {
            if (i == 0) {
                result = _errors[i];
            } else {
                result = string(abi.encodePacked(result, "; ", _errors[i]));
            }
        }
        return result;
    }
}

contract ProcurementSystemDeployer {
    address public cfoAddress;
    DailyLimitManager public dailyLimitManager;
    PurchaseAgreementManager public agreementManager;
    FraudDetection public fraudDetection;
    ZKInvoiceVerifier public zkInvoiceVerifier;
    EnhancedInvoiceVerification public invoiceVerification;
    
    // Alamat verifier Honk yang sudah deployed
    address public constant HONK_VERIFIER_ADDRESS = 0x9E7C8251F45C881D42957042224055d32445805C;
    
    constructor(address _cfoAddress) {
        cfoAddress = _cfoAddress;
        
        // Deploy contracts dalam urutan yang benar
        dailyLimitManager = new DailyLimitManager(_cfoAddress);
        agreementManager = new PurchaseAgreementManager(_cfoAddress);
        fraudDetection = new FraudDetection(_cfoAddress);
        
        // Deploy ZK invoice verifier terlebih dahulu
        zkInvoiceVerifier = new ZKInvoiceVerifier(HONK_VERIFIER_ADDRESS);
        
        // Deploy enhanced invoice verification dengan ZK integration
        invoiceVerification = new EnhancedInvoiceVerification(
            address(dailyLimitManager),
            address(agreementManager),
            address(fraudDetection),
            _cfoAddress,
            address(zkInvoiceVerifier)
        );
        
        // Setup initial categories
        setupInitialCategories();
    }
    
    function setupInitialCategories() internal {
        dailyLimitManager.setCategoryLimit("Electronics", 50000000000000000000000000);
        dailyLimitManager.setCategoryLimit("Office Supplies", 25000000000000000000000000);
        dailyLimitManager.setCategoryLimit("Furniture", 75000000000000000000000000);
        dailyLimitManager.setCategoryLimit("Software", 100000000000000000000000000);
    }
    
    function getContractAddresses() external view returns (
        address dailyLimit,
        address agreementManagerAddr,
        address fraudDetectionAddr,
        address invoiceVerificationAddr,
        address zkVerifierAddr
    ) {
        return (
            address(dailyLimitManager),
            address(agreementManager),
            address(fraudDetection),
            address(invoiceVerification),
            address(zkInvoiceVerifier)
        );
    }
}