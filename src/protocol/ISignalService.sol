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
        bytes32 stateRoot;
        bytes32 blockHash;
    }

    /// @dev Emitted when a signal is sent.
    /// @param sender The address that sent the signal on the source chain
    /// @param value The signal value
    event SignalSent(address indexed sender, bytes32 value);

    /// @dev Emitted when a signal is verified.
    /// @param sender The address of the sender on the source chain
    /// @param value Value that was signaled
    event SignalVerified(address indexed sender, bytes32 value);

    /// @dev We require the commitment to contain a state root (with an embedded storage root)
    error StorageRootCommitmentNotSupported();

    /// @dev If the commitment returns 0 we assume it does not exist
    error CommitmentNotFound();

    /// @dev The commitment does not match the block hash and state root
    error InvalidCommitment();

    /// @notice Stores a signal and returns its storage location.
    /// @param value Data to be stored (signalled)
    function sendSignal(bytes32 value) external returns (bytes32 slot);

    /// @notice Checks if a signal has been stored
    /// @dev Note: This does not mean it has been 'sent' to destination chain,
    /// only that it has been stored on the source chain.
    /// @param value Value to be checked is stored
    /// @param sender The address that sent the signal
    function isSignalStored(bytes32 value, address sender) external view returns (bool);

    /// @notice Verifies if the signal can be proved to be part of a merkle tree. This is usually used to verify signals
    /// sent by `sender` on the source chain, which state is represented by `commitmentPublisher` at `height`.
    /// @dev Signals are not deleted when verified, and can be
    /// verified multiple times by calling this function
    /// @param height A reference value indicating which trusted root to use for verification
    /// see ICommitmentStore for more information
    /// @param commitmentPublisher The address that published the commitment
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
