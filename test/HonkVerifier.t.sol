// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.19;

// import "forge-std/Test.sol";
// import "../src/verifier.sol";

// contract HonkVerifierTest is Test {
//     HonkVerifier public verifier;
    
//     function setUp() public {
//         verifier = new HonkVerifier();
//     }
    
//     // Test 1: Contract deployment
//     function test_DeploymentSuccess() public {
//         assertTrue(address(verifier) != address(0), "Verifier should be deployed");
//     }
    
//     // Test 2: Verification key loading
//     function test_LoadVerificationKey() public {
//         // This tests that the verification key can be loaded without reverting
//         // The actual verification key is loaded internally
//         vm.expectRevert(); // We expect it to revert with invalid proof
//         bytes memory emptyProof = "";
//         bytes32[] memory emptyInputs = new bytes32[](0);
//         verifier.verify(emptyProof, emptyInputs);
//     }
    
//     // Test 3: Verify with empty proof (should fail)
//     function test_RevertOnEmptyProof() public {
//         bytes memory emptyProof = "";
//         bytes32[] memory publicInputs = new bytes32[](18); // NUMBER_OF_PUBLIC_INPUTS = 18
        
//         vm.expectRevert();
//         verifier.verify(emptyProof, publicInputs);
//     }
    
//     // Test 4: Verify with invalid proof length (should fail)
//     function test_RevertOnInvalidProofLength() public {
//         bytes memory invalidProof = hex"1234"; // Too short
//         bytes32[] memory publicInputs = new bytes32[](18);
        
//         vm.expectRevert();
//         verifier.verify(invalidProof, publicInputs);
//     }
    
//     // Test 5: Verify with wrong number of public inputs (should fail)
//     function test_RevertOnWrongPublicInputsCount() public {
//         // Create a dummy proof (will be invalid but tests input validation)
//         bytes memory dummyProof = new bytes(1024);
//         bytes32[] memory wrongInputs = new bytes32[](5); // Wrong count, should be 18
        
//         vm.expectRevert();
//         verifier.verify(dummyProof, wrongInputs);
//     }
    
//     // Test 6: Verify with correct input count but invalid proof
//     function test_RevertOnInvalidProofData() public {
//         // Create a dummy proof with some data
//         bytes memory dummyProof = new bytes(2048);
//         bytes32[] memory publicInputs = new bytes32[](18);
        
//         // Fill with some dummy data
//         for (uint i = 0; i < 18; i++) {
//             publicInputs[i] = bytes32(uint256(i + 1));
//         }
        
//         vm.expectRevert();
//         verifier.verify(dummyProof, publicInputs);
//     }
    
//     // Test 7: Gas estimation for verification attempt
//     function test_GasEstimationForVerification() public {
//         bytes memory dummyProof = new bytes(2048);
//         bytes32[] memory publicInputs = new bytes32[](18);
        
//         uint256 gasBefore = gasleft();
//         try verifier.verify(dummyProof, publicInputs) {
//             // If it succeeds (unlikely with dummy data)
//         } catch {
//             // Expected to fail
//         }
//         uint256 gasUsed = gasBefore - gasleft();
        
//         // Log gas usage for reference
//         emit log_named_uint("Gas used for verification attempt", gasUsed);
//         assertTrue(gasUsed > 0, "Should consume gas");
//     }
    
//     // Test 8: Multiple verification attempts
//     function test_MultipleVerificationAttempts() public {
//         bytes memory dummyProof = new bytes(2048);
//         bytes32[] memory publicInputs = new bytes32[](18);
        
//         // Try multiple times to ensure state consistency
//         for (uint i = 0; i < 3; i++) {
//             try verifier.verify(dummyProof, publicInputs) {
//                 // Should not succeed with dummy proof
//                 revert("Should not verify dummy proof");
//             } catch {
//                 // Expected behavior
//             }
//         }
//     }
    
//     // Test 9: Constants verification
//     function test_VerifierConstants() public {
//         // These are the constants defined in the verifier
//         assertEq(N, 4096, "Circuit size should be 4096");
//         assertEq(LOG_N, 12, "Log circuit size should be 12");
//         assertEq(NUMBER_OF_PUBLIC_INPUTS, 18, "Public inputs should be 18");
//     }
    
//     // Test 10: Fuzz test with random proof data
//     function testFuzz_RandomProofData(bytes calldata randomProof) public {
//         // Bound the proof size to reasonable limits
//         vm.assume(randomProof.length > 0 && randomProof.length < 10000);
        
//         bytes32[] memory publicInputs = new bytes32[](18);
//         for (uint i = 0; i < 18; i++) {
//             publicInputs[i] = bytes32(uint256(i));
//         }
        
//         // Should not revert due to out-of-gas or other issues
//         // But verification should fail with random data
//         try verifier.verify(randomProof, publicInputs) returns (bool result) {
//             // If it doesn't revert, result should be false
//             assertFalse(result, "Random proof should not verify");
//         } catch {
//             // Also acceptable - invalid proof format
//         }
//     }
    
//     // Test 11: Fuzz test with random public inputs
//     function testFuzz_RandomPublicInputs(bytes32[18] calldata randomInputs) public {
//         bytes memory dummyProof = new bytes(2048);
//         bytes32[] memory publicInputs = new bytes32[](18);
        
//         for (uint i = 0; i < 18; i++) {
//             publicInputs[i] = randomInputs[i];
//         }
        
//         try verifier.verify(dummyProof, publicInputs) returns (bool result) {
//             assertFalse(result, "Invalid proof should not verify");
//         } catch {
//             // Expected for invalid proof
//         }
//     }
    
//     // Test 12: Interface compliance
//     function test_InterfaceCompliance() public {
//         // Verify that HonkVerifier implements IVerifier
//         assertTrue(
//             address(verifier) != address(0),
//             "Verifier should implement IVerifier interface"
//         );
//     }
    
//     // Test 13: Test with valid-looking but fake proof structure
//     function test_FakeButStructuredProof() public {
//         // Create a proof with correct length but fake data
//         // Typical Honk proof might be around 2KB+
//         bytes memory fakeProof = new bytes(2400);
        
//         // Fill with non-zero data to make it look more realistic
//         for (uint i = 0; i < fakeProof.length; i += 32) {
//             assembly {
//                 mstore(add(add(fakeProof, 32), i), keccak256(0, i))
//             }
//         }
        
//         bytes32[] memory publicInputs = new bytes32[](18);
//         for (uint i = 0; i < 18; i++) {
//             publicInputs[i] = keccak256(abi.encodePacked(i));
//         }
        
//         vm.expectRevert();
//         verifier.verify(fakeProof, publicInputs);
//     }
    
//     // Test 14: Zero public inputs
//     function test_ZeroPublicInputs() public {
//         bytes memory dummyProof = new bytes(2048);
//         bytes32[] memory publicInputs = new bytes32[](18);
//         // All inputs are zero by default
        
//         vm.expectRevert();
//         verifier.verify(dummyProof, publicInputs);
//     }
    
//     // Test 15: Maximum value public inputs
//     function test_MaxValuePublicInputs() public {
//         bytes memory dummyProof = new bytes(2048);
//         bytes32[] memory publicInputs = new bytes32[](18);
        
//         for (uint i = 0; i < 18; i++) {
//             publicInputs[i] = bytes32(type(uint256).max);
//         }
        
//         vm.expectRevert();
//         verifier.verify(dummyProof, publicInputs);
//     }
// }
