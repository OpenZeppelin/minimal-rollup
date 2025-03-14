// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Interface for a verifier contract that handles proof verification.
interface IVerifier {
    error InvalidProof();

    function verifyProof(
        bytes32, /* startPublicationHash */
        bytes32, /* endPublicationHash */
        bytes32, /* startCheckPoint */
        bytes32, /* endCheckPoint */
        bytes calldata /* proof */
    ) external;
}
