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
    /// @param signal Signal value that was verified
    /// @param chainId Chain ID where the signal was sent to
    /// @param root TODO: check this
    event SignalVerified(bytes32 signal, uint64 chainId, bytes32 root);

    /// @dev Emitted when a signal fails to be verified.
    /// @param signal Signal value that was not verified
    /// @param root TODO: check this
    error SignalNotSent(bytes32 signal, bytes32 root);

    /// @dev Stores a data signal and returns its storage location.
    /// @param value Data signal to be stored
    function sendSignal(bytes32 value) external returns (bytes32 slot);

    /// @dev Checks if a signal has been sent.
    /// @param signal Signal value to be checked
    function isSignalSent(bytes32 signal) external view returns (bool);

    /// @dev Verifies if the signal can be proved to be part of a merkle tree
    /// defined by `root` for the specified signal service storage.
    /// @param account Account address that stores the signal (address(this))
    /// @param root TODO: check this
    /// @param chainId Chain ID where the signal was sent to
    /// @param signal Signal value to be verified
    /// @param accountProof Merkle proof for account state against global stateRoot
    /// @param stateProof Merkle proof for slot value against account's storageRoot
    function verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 signal,
        bytes[] memory accountProof,
        bytes[] memory stateProof
    ) external;
}
