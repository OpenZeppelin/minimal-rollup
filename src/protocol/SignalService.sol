// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../libs/LibSignal.sol";
import {CommitmentStore} from "./CommitmentStore.sol";
import {ETHBridge} from "./ETHBridge.sol";

import {ICommitmentStore} from "./ICommitmentStore.sol";
import {ISignalService} from "./ISignalService.sol";

/// @dev SignalService is used for secure cross-chain messaging
///
/// This contract allows sending arbitrary data as signals via `sendSignal` and verifying signals from other chains
/// using`verifySignal`
///   It integrates:
///    - `CommitmentStore` to access state roots,
///    - `LibSignal` for signal hashing, storage, and verification logic.
///
/// Signals stored cannot be deleted
/// IMPORTANT: This contract should be deployed on the same address on both chains.
/// WARN: this contract does not provide replay protection(signals can be verified multiple times).
contract SignalService is ISignalService, CommitmentStore {
    using LibSignal for bytes32;

    /// @inheritdoc ISignalService
    /// @dev Signals are stored in a namespaced slot derived from the signal value and sender address
    function sendSignal(bytes32 value) external returns (bytes32 slot) {
        slot = value.signal();
        emit SignalSent(msg.sender, value);
    }

    /// @inheritdoc ISignalService
    function isSignalStored(bytes32 value, address sender) external view returns (bool) {
        return value.signaled(sender);
    }

    /// @inheritdoc ISignalService
    /// @dev This function assumes that the commitment is the `keccak256(stateRoot, blockHash)` of the origin chain to
    /// be able to use the `stateRoot` to verify the signal.
    function verifySignal(
        uint256 height,
        address commitmentPublisher,
        address sender,
        bytes32 value,
        bytes memory proof
    ) external {
        bytes32 commitment = commitmentAt(commitmentPublisher, height);
        // A 0 root will fail the hash comparison, but better to explicitly check and return an error
        require(commitment != 0, CommitmentNotFound());

        SignalProof memory signalProof = abi.decode(proof, (SignalProof));
        bytes32 blockHash = signalProof.blockHash;
        bytes32 stateRoot = signalProof.stateRoot;
        require(keccak256(abi.encode(stateRoot, blockHash)) == commitment, InvalidCommitment());

        bytes[] memory accountProof = signalProof.accountProof;
        bytes[] memory storageProof = signalProof.storageProof;
        // We only support state roots for verification
        // this is to avoid state roots being used as storage roots (for safety)
        require(accountProof.length != 0, StorageRootCommitmentNotSupported());

        value.verifySignal(sender, stateRoot, accountProof, storageProof);

        emit SignalVerified(sender, value);
    }
}
