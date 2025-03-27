// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../../libs/LibSignal.sol";
import {LibTrieProof} from "../../libs/LibTrieProof.sol";
import {CheckpointSyncer} from "../CheckpointSyncer.sol";
import {ETHBridge} from "../ETHBridge.sol";
import {ICheckpointTracker} from "../ICheckpointTracker.sol";
import {ISignalService} from "../ISignalService.sol";

/// @dev Implementation of a secure cross-chain messaging system for broadcasting arbitrary data (i.e. signals).
///
/// The service defines the minimal logic to broadcast signals through `sendSignal` and verify them with
/// `verifySignal`. The service is designed to be used in conjunction with the `ETHBridge` contract to
/// enable cross-chain communication.
contract SignalService is ISignalService, ETHBridge, CheckpointSyncer {
    using LibSignal for bytes32;

    constructor(address _checkpointTracker) CheckpointSyncer(_checkpointTracker) {}

    /// @inheritdoc ISignalService
    function sendSignal(bytes32 value) external returns (bytes32 signal) {
        signal = value.signal();
        emit SignalSent(signal);
    }

    /// @inheritdoc ISignalService
    function isSignalStored(bytes32 value) external view returns (bool) {
        // This will return `false` when the signal itself is 0
        return value.signaled();
    }

    /// @inheritdoc ISignalService
    function verifySignal(
        bytes32 root,
        uint64 chainId,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external {
        // TODO: Get the root from the trusted source
        _verifySignal(root, chainId, value, accountProof, storageProof);

        emit SignalVerified(value, chainId, root);
    }

    /// @dev Overrides ETHBridge.depositETH to add signaling functionality.
    function depositETH(uint64 chainId, address to, bytes memory data) public payable override returns (bytes32 id) {
        id = super.depositETH(chainId, to, data);
        id.signal();
    }

    // CHECK: Should this function be non-reentrant?
    /// @inheritdoc ETHBridge
    /// @dev Overrides ETHBridge.claimDeposit to add signal verification logic.
    function claimDeposit(ETHDeposit memory deposit, bytes32 root, bytes[] memory accountProof, bytes[] memory proof)
        external
        override
        returns (bytes32 id)
    {
        id = _generateId(deposit);

        _verifySignal(root, deposit.chainId, id, accountProof, proof);

        super._processClaimDepositWithId(id, deposit);
    }

    function syncCheckpoint(ICheckpointTracker.Checkpoint memory checkpoint, uint64 chainId)
        public
        override
        returns (bytes32 id)
    {
        id = super.syncCheckpoint(checkpoint, chainId);
        id.signal();
    }

    function verifyCheckpoint(
        ICheckpointTracker.Checkpoint memory checkpoint,
        uint64 chainId,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory proof
    ) public view override returns (bytes32 id) {
        id = getCheckpointId(checkpoint, chainId);
        _verifySignal(root, chainId, id, accountProof, proof);
    }

    function _verifySignal(
        bytes32 root,
        uint64 chainId,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory stateProof
    ) internal view {
        (bool valid,) = LibSignal.verifySignal(address(this), root, chainId, value, accountProof, stateProof);
        require(valid, SignalNotReceived(value, root));
    }
}
