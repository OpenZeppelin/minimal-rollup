// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVerifier {
    /// @notice Verifies a proof of a checkpoint between two publication hashes
    function verifyProof(
        bytes32 startPublicationHash,
        bytes32 endPublicationHash,
        bytes32 startCheckPoint,
        bytes32 endCheckPoint,
        uint256 numPublications,
        bytes calldata proof
    ) external;
}
