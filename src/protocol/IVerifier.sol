// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVerifier {
    /// @notice Verifies a proof of a checkpoint between two publication hashes
    /// @dev The numDelayedPublications value corresponds to the delayed publications
    /// between intermediateCheckpoint (which may be the startCheckPoint) and endCheckPoint
    function verifyProof(
        bytes32 startPublicationHash,
        bytes32 endPublicationHash,
        bytes32 startCheckPoint,
        bytes32 endCheckPoint,
        bytes32 intermediateCheckPoint,
        uint256 numDelayedPublications,
        bytes calldata proof
    ) external;
}
