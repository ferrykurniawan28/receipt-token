// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SimpleReceiptImages.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract SimpleReceiptTest is Test, IERC721Receiver {
    SimpleReceiptImages public receiptContract;
    address public alice = address(0x123);
    address public bob = address(0x456);
    
    // Events for testing
    event ImageStored(uint256 indexed tokenId, address indexed uploadedBy, string imageCID);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // Implement IERC721Receiver
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setUp() public {
        receiptContract = new SimpleReceiptImages();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
    }

    // Test 1: Basic CID storage
    function test_StoreCID() public {
        string memory testCID = "QmXyz123abc";
        
        uint256 tokenId = receiptContract.storeReceiptImage(testCID);
        
        assertEq(tokenId, 1, "First token ID should be 1");
        assertEq(receiptContract.getImageCID(tokenId), testCID, "CID should match");
        assertEq(receiptContract.ownerOf(tokenId), address(this), "Caller should own token");
        assertTrue(receiptContract.cidExists(testCID), "CID should be marked as existing");
    }

    // Test 2: Duplicate CID prevention
    function test_DuplicateCID() public {
        string memory testCID = "QmXyz123abc";
        
        receiptContract.storeReceiptImage(testCID);
        
        vm.expectRevert("CID already exists");
        receiptContract.storeReceiptImage(testCID);
    }

    // Test 3: Empty CID rejection
    function test_EmptyCID() public {
        vm.expectRevert("CID required");
        receiptContract.storeReceiptImage("");
    }

    // Test 4: Multiple users storing different CIDs
    function test_MultipleUsers() public {
        string memory aliceCID = "QmAlice123";
        string memory bobCID = "QmBob456";
        
        vm.prank(alice);
        uint256 aliceTokenId = receiptContract.storeReceiptImage(aliceCID);
        
        vm.prank(bob);
        uint256 bobTokenId = receiptContract.storeReceiptImage(bobCID);
        
        assertEq(aliceTokenId, 1, "Alice should get token ID 1");
        assertEq(bobTokenId, 2, "Bob should get token ID 2");
        assertEq(receiptContract.ownerOf(aliceTokenId), alice, "Alice should own her token");
        assertEq(receiptContract.ownerOf(bobTokenId), bob, "Bob should own his token");
        assertEq(receiptContract.getImageCID(aliceTokenId), aliceCID, "Alice's CID should match");
        assertEq(receiptContract.getImageCID(bobTokenId), bobCID, "Bob's CID should match");
    }

    // Test 5: Token counter increments correctly
    function test_TokenCounterIncrement() public {
        assertEq(receiptContract.totalImages(), 0, "Should start with 0 images");
        
        receiptContract.storeReceiptImage("QmFirst");
        assertEq(receiptContract.totalImages(), 1, "Should have 1 image after first mint");
        
        receiptContract.storeReceiptImage("QmSecond");
        assertEq(receiptContract.totalImages(), 2, "Should have 2 images after second mint");
    }

    // Test 6: Get image URL
    function test_GetImageURL() public {
        string memory testCID = "QmTest456";
        
        uint256 tokenId = receiptContract.storeReceiptImage(testCID);
        string memory imageURL = receiptContract.getImageURL(tokenId);
        
        string memory expectedURL = string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/", testCID));
        assertEq(imageURL, expectedURL, "URL should use Pinata gateway");
    }

    // Test 7: Token URI generation and base64 encoding
    function test_TokenURI() public {
        string memory testCID = "QmTestURI789";
        
        uint256 tokenId = receiptContract.storeReceiptImage(testCID);
        string memory tokenURI = receiptContract.tokenURI(tokenId);
        
        assertTrue(bytes(tokenURI).length > 0, "Token URI should not be empty");
        
        // Check if it starts with the expected base64 JSON prefix
        bytes memory prefix = "data:application/json;base64,";
        bytes memory tokenURIBytes = bytes(tokenURI);
        
        bool startsWithPrefix = true;
        if (tokenURIBytes.length < prefix.length) {
            startsWithPrefix = false;
        } else {
            for (uint i = 0; i < prefix.length; i++) {
                if (tokenURIBytes[i] != prefix[i]) {
                    startsWithPrefix = false;
                    break;
                }
            }
        }
        
        assertTrue(startsWithPrefix, "Token URI should be base64 encoded JSON");
    }

    // Test 8: ERC721 compliance - transfer
    function test_Transfer() public {
        string memory testCID = "QmTransfer123";
        uint256 tokenId = receiptContract.storeReceiptImage(testCID);
        
        vm.expectEmit(true, true, true, false);
        emit Transfer(address(this), alice, tokenId);
        
        receiptContract.transferFrom(address(this), alice, tokenId);
        
        assertEq(receiptContract.ownerOf(tokenId), alice, "Alice should own token after transfer");
        assertEq(receiptContract.balanceOf(alice), 1, "Alice should have 1 token");
        assertEq(receiptContract.balanceOf(address(this)), 0, "Original owner should have 0 tokens");
    }

    // Test 9: Non-existent token queries should fail
    function test_NonExistentToken() public {
        vm.expectRevert("Token doesn't exist");
        receiptContract.getImageCID(999);
        
        vm.expectRevert("Token doesn't exist");
        receiptContract.getImageURL(999);
    }

    // Test 10: Contract metadata
    function test_ContractMetadata() public {
        assertEq(receiptContract.name(), "SimpleReceipts", "Contract name should be correct");
        assertEq(receiptContract.symbol(), "SRCPT", "Contract symbol should be correct");
    }

    // Test 11: Ownership functionality
    function test_Ownership() public {
        assertEq(receiptContract.owner(), address(this), "Deployer should be owner");
        
        receiptContract.transferOwnership(alice);
        assertEq(receiptContract.owner(), alice, "Alice should be new owner");
    }

    // Test 12: Supports interface
    function test_SupportsInterface() public {
        // ERC721 interface ID: 0x80ac58cd
        assertTrue(receiptContract.supportsInterface(0x80ac58cd), "Should support ERC721");
        
        // ERC721Metadata interface ID: 0x5b5e139f
        assertTrue(receiptContract.supportsInterface(0x5b5e139f), "Should support ERC721Metadata");
        
        // Random interface should not be supported
        assertFalse(receiptContract.supportsInterface(0x12345678), "Should not support random interface");
    }

    // Test 13: Fuzz test for CID storage
    function testFuzz_StoreCID(string memory cid) public {
        vm.assume(bytes(cid).length > 0 && bytes(cid).length <= 100);
        vm.assume(!receiptContract.cidExists(cid));
        
        uint256 tokenId = receiptContract.storeReceiptImage(cid);
        
        assertEq(receiptContract.getImageCID(tokenId), cid, "CID should match input");
        assertTrue(receiptContract.cidExists(cid), "CID should be marked as existing");
    }

    // Test 14: Batch operations
    function test_BatchStorage() public {
        string[5] memory cids = [
            "QmBatch1",
            "QmBatch2", 
            "QmBatch3",
            "QmBatch4",
            "QmBatch5"
        ];
        
        for (uint i = 0; i < cids.length; i++) {
            uint256 tokenId = receiptContract.storeReceiptImage(cids[i]);
            assertEq(tokenId, i + 1, "Token ID should increment");
            assertEq(receiptContract.getImageCID(tokenId), cids[i], "CID should match");
        }
        
        assertEq(receiptContract.totalImages(), 5, "Should have 5 total images");
    }

    // Test 15: Event emission
    function test_EventEmission() public {
        string memory testCID = "QmEventTest123";
        
        // Test ImageStored event
        vm.expectEmit(true, true, false, true);
        emit ImageStored(1, address(this), testCID);
        
        receiptContract.storeReceiptImage(testCID);
    }

    // Test 16: Gas optimization test
    function test_GasOptimization() public {
        string memory testCID = "QmGasTest123";
        
        uint256 gasBefore = gasleft();
        receiptContract.storeReceiptImage(testCID);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Log gas usage for monitoring
        emit log_named_uint("Gas used for storing CID", gasUsed);
        
        // Ensure it's within reasonable bounds (adjusted threshold)
        assertLt(gasUsed, 400000, "Gas usage should be reasonable");
    }
}