// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../libs/LibSignal.sol";
import {CommitmentStore} from "./CommitmentStore.sol";
import {ETHBridge} from "./ETHBridge.sol";
import {ISignalService} from "./ISignalService.sol";

/// @dev SignalService is used for secure cross-chain messaging
///
/// This contract allows sending arbitrary data as signals via `sendSignal`, verifying signals from other chains using
/// `verifySignal`, and bridging native ETH with built-in signal generation and verification. It integrates:
/// - `CommitmentStore` to access state roots,
/// - `LibSignal` for signal hashing, storage, and verification logic.
///
/// Signals stored cannot be deleted and can be verified multiple times.
contract SignalService is ISignalService, CommitmentStore {
    using LibSignal for bytes32;

    /// @inheritdoc ISignalService
    /// @dev Signals are stored in a namespaced slot derived from the signal value, sender address and SIGNAL_NAMESPACE
    /// const
    /// @dev Cannot be used to send eth bridge signals
    function sendSignal(bytes32 value) external returns (bytes32 slot) {
        slot = value.signal();
        emit SignalSent(msg.sender, value);
    }

    /// @inheritdoc ISignalService
    function isSignalStored(bytes32 value, address sender) external view returns (bool) {
        return value.signaled(sender);
    }

    /// @inheritdoc ISignalService
    function verifySignal(
        uint256 height,
        address commitmentPublisher,
        address sender,
        bytes32 value,
        bytes memory proof
    ) external {
        // TODO: commitmentAt(height) might not be the 'state root' of the chain
        // For now it could be the block hash or other hashed value
        // further work is needed to ensure we get the 'state root' of the chain
        bytes32 root = commitmentAt(commitmentPublisher, height);
        SignalProof memory signalProof = abi.decode(proof, (SignalProof));
        bytes[] memory accountProof = signalProof.accountProof;
        bytes[] memory storageProof = signalProof.storageProof;
        // if there is no account proof, verify signal will treat root as a storage root
        // instead of a full state root which we currently do not support
        require(accountProof.length != 0, StateProofNotSupported());
        value.verifySignal(sender, root, accountProof, storageProof);
        emit SignalVerified(sender, value);
    }
}
