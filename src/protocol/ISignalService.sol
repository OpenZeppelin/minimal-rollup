// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ISignalService
/// @dev Secure cross-chain messaging system for broadcasting arbitrary data (i.e. signals).
///
/// Signals enable generalized on-chain communication, primarily for data transmission rather than value transfer.
/// Applications can leverage signals to transfer value through secondary implementations.
///
/// Signals are broadcast without specific recipients, allowing flexible cross-chain messaging
interface ISignalService {
    /// @dev Emitted when a signal is sent.
    /// @param chainId The chain ID of the source chain where the signal was sent
    /// @param sender The address that sent the signal on the source chain
    /// @param value The signal value
    event SignalSent(address sender, uint256 chainId, bytes32 value);

    /// @dev Emitted when a signal is verified.
    /// @param chainId The chain ID of the source chain where the signal was sent
    /// @param value Value that was signaled
    event SignalVerified(uint64 chainId, address sender, bytes32 value);

    /// @dev Error when a signal fails to be verified.
    /// @param value Value that was not verified
    error SignalNotReceived(bytes32 value);

    /// @dev Stores a data signal and returns its storage location.
    /// @param value Data to be stored (signalled)
    function sendSignal(bytes32 value) external returns (bytes32 slot);

    /// @dev Checks if a signal has been stored
    /// @dev Note: This does not mean it has been 'sent' to destination chain,
    /// only that it has been stored on the source chain.
    /// @param value Value to be checked is stored
    /// @param sender The address that sent the signal
    function isSignalStored(bytes32 value, address sender) external view returns (bool);

    /// @dev Verifies if the signal can be proved to be part of a merkle tree
    /// @dev Signals are not deleted when verified, and can be
    /// verified multiple times by calling this function
    /// @dev see `LibSignal.verifySignal`
    /// @dev Height refers to the block number / commitmentId where the trusted root is mapped to
    function verifySignal(
        uint64 chainId,
        uint256 height,
        address sender,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external;
}
