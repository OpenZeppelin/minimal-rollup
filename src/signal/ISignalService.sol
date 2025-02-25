// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


/// @dev Secure cross-chain messaging system for broadcasting arbitrary data (i.e. signals).
///
/// Signals enable generalized on-chain communication, primarily for data transmission rather than value transfer.
/// Applications can leverage signals to transfer value through secondary implementations.
///
/// Signals are broadcast without specific recipients, allowing flexible cross-chain data sourcing from any
/// source chain state (e.g., full transaction logs or contract storage).
interface ISignalService {
    event SignalsReceived(bytes32[] slots);

    /// @dev Not the checkpoint tracker contract
    error UnauthorizedCheckpoints(address caller);

    /// @dev CheckpointTracker contract.
    function checkpointTracker() external view returns (address);

    /// @dev The signal is sent.
    function signalSent(address account, bytes32 signal) external view returns (bool sent);

    /// @dev Same as `signalSent` that takes the slot as input.
    function signalSent(bytes32 slot) external view returns (bool sent);

    /// @dev The signal is received (not verified). Consider using `verifySignal`.
    function signalReceived(uint64 chainId, address account, bytes32 signal) external view returns (bool received);

    /// @dev Same as `signalReceived` that takes the slot as input.
    function signalReceived(bytes32 slot) external view returns (bool received);

    /// @dev Derives a namespaced storage slot to store the signal following ERC-7201 to avoid storage collisions.
    function signalSlot(uint64 chainId, address account, bytes32 signal) external pure returns (bytes32 slot);

    /// @dev Stores a data signal and returns its storage location.
    function sendSignal(bytes32 signal) external returns (bytes32 slot);

    /// @dev Marks signals from specified storage slots as received. Useful to provide a signal not yet verifiable.
    function receiveSignal(bytes32[] calldata slots) external;

    /// @dev Verifies if the signal can be proved to be part of a merkle tree defined by `root` for the specified
    /// signal service storage. See `signalSlot` for the storage slot derivation.
    function verifySignal(
        address signalService,
        bytes32 root,
        uint64 chainId,
        bytes32 signal,
        bytes[] calldata accountProof,
        bytes[] calldata storageProof
    ) external returns (bool valid, bytes32 storageRoot);
}
