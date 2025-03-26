// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ISignalService
/// @dev Secure cross-chain messaging system for broadcasting arbitrary data (i.e. signals).
///
/// Signals enable generalized on-chain communication, primarily for data transmission rather than value transfer.
/// Applications can leverage signals to transfer value through secondary implementations.
///
/// Signals are broadcast without specific recipients, allowing flexible cross-chain data sourcing from any
/// source chain state (e.g., full transaction logs or contract storage).
interface ISignalService {
    /// @dev Stores a data signal and returns its storage location.
    function sendSignal(bytes32 value) external returns (bytes32 slot);

    /// @dev Verifies if the signal can be proved to be part of a merkle tree defined by `root` for the specified
    /// signal service storage. See `signalSlot` for the storage slot derivation.
    function verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external pure;
}
