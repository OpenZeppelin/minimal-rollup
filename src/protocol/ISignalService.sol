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
    /// @dev Emitted when a signal is sent.
    /// @param signal Signal value that was stored
    event SignalSent(bytes32 signal);

    /// @dev Emitted when a signal is verified.
    /// @param value Value that was signaled
    /// @param chainId Chain ID where the signal was sent to
    /// @param root TODO: check this
    event SignalVerified(bytes32 value, uint64 chainId, bytes32 root);

    /// @dev Error when a signal fails to be verified.
    /// @param value Value that was not verified
    error SignalNotReceived(bytes32 value, bytes32 root);

    /// @dev Stores a data signal and returns its storage location.
    /// @param value Data to be stored (signalled)
    function sendSignal(bytes32 value) external returns (bytes32 slot);

    /// @dev Checks if a signal has been stored
    /// @dev Note: This does not mean it has been 'sent' to destination chain, only that it has been stored on the
    /// source chain.
    /// @param value Value to be checked is stored
    // @param sender The address that sent the signal
    function isSignalStored(bytes32 value, address sender) external view returns (bool);

    /// @dev Verifies if the signal can be proved to be part of a merkle tree
    /// defined by `root` for the specified signal service storage.
    /// @param root TODO: check this
    /// @param chainId Chain ID where the signal was sent to
    /// @param value Value to be verified
    /// @param accountProof Merkle proof for account state against global stateRoot
    /// @param stateProof Merkle proof for slot value against account's storageRoot
    function verifySignal(
        bytes32 root,
        uint64 chainId,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory stateProof
    ) external;
}
