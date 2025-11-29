// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Mock verifier for testing - avoids stack too deep issues
contract MockHonkVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external pure returns (bool) {
        // Mock implementation for testing
        // In real deployment, use the actual HonkVerifier
        return _proof.length > 0 && _publicInputs.length > 0;
    }
}

// Interface for the real HonkVerifier
interface IHonkVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external returns (bool);
}