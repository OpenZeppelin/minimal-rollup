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
    struct SignalProof {
        bytes[] accountProof;
        bytes[] storageProof;
    }

    /// @dev Emitted when a signal is sent.
    /// @param sender The address that sent the signal on the source chain
    /// @param namespace The namespace of the signal
    /// @param value The signal value
    event SignalSent(address indexed sender, bytes32 namespace, bytes32 value);

    /// @dev Emitted when a signal is verified.
    /// @param sender The address of the sender on the source chain
    /// @param value Value that was signaled
    event SignalVerified(address indexed sender, bytes32 value);

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
    /// @param namespace The namespace of the signal
    function isSignalStored(bytes32 value, address sender, bytes32 namespace) external view returns (bool);

    /// @dev Verifies if the signal can be proved to be part of a merkle tree
    /// @dev Signals are not deleted when verified, and can be
    /// verified multiple times by calling this function
    /// @param height This refers to the block number / commitmentId where the trusted root is mapped to
    /// @param commitmentPublisher The address that published the commitment containing the signal.
    /// @param sender The address that originally sent the signal on the source chain
    /// @param value The signal value to verify
    /// @param proof The encoded value of the SignalProof struct
    function verifySignal(
        uint256 height,
        address commitmentPublisher,
        address sender,
        bytes32 value,
        bytes memory proof
    ) external;
}
