// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ISignalService
/// @notice Interface for the SignalService contract.
interface ISignalService {
    error SignalNotReceived();
    error CallerNotAuthorised();

    event SignalsReceived(bytes32[] signalSlots);

    function sendSignal(bytes32 value) external returns (bytes32);

    function receiveSignals(bytes32[] calldata signalSlots) external;

    function verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external view;

    function isSignalSent(bytes32 signal) external view returns (bool);
}
