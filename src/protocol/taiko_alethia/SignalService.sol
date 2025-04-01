// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../../libs/LibSignal.sol";
import {LibTrieProof} from "../../libs/LibTrieProof.sol";
import {CommitmentStore} from "../CommitmentStore.sol";
import {ETHBridge} from "../ETHBridge.sol";
import {ICheckpointTracker} from "../ICheckpointTracker.sol";
import {ISignalService} from "../ISignalService.sol";

/// @dev Implementation of a secure cross-chain messaging system for broadcasting arbitrary data (i.e. signals).
///
/// The service defines the minimal logic to broadcast signals through `sendSignal` and verify them with
/// `verifySignal`. The service is designed to be used in conjunction with the `ETHBridge` contract to
/// enable cross-chain communication and the CommitmentStore to retrieve trusted state roots.
contract SignalService is ISignalService, ETHBridge, CommitmentStore {
    using LibSignal for bytes32;

    /// @inheritdoc ISignalService
    function sendSignal(bytes32 value) external returns (bytes32 slot) {
        slot = value.signal();
        emit SignalSent(msg.sender, block.chainid, value);
    }

    /// @inheritdoc ISignalService
    function isSignalStored(bytes32 value, address sender) external view returns (bool) {
        // This will return `false` when the signal itself is 0
        return LibSignal.signaled(sender, value);
    }

    /// @inheritdoc ISignalService
    function verifySignal(
        uint64 chainId,
        uint256 height,
        address sender,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external {
        _verifySignal(chainId, height, sender, value, accountProof, storageProof);
        emit SignalVerified(chainId, sender, value);
    }

    /// @dev Overrides ETHBridge.depositETH to add signaling functionality.
    function depositETH(uint64 chainId, uint256 fee, uint256 gasLimit, address to, bytes memory data)
        public
        payable
        override
        returns (bytes32 id)
    {
        id = super.depositETH(chainId, fee, gasLimit, to, data);
        id.signal();
    }

    // CHECK: Should this function be non-reentrant?
    /// @inheritdoc ETHBridge
    /// @dev Overrides ETHBridge.claimDeposit to add signal verification logic.
    function claimDeposit(
        ETHDeposit memory deposit,
        uint256 height,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external override returns (bytes32 id) {
        id = _generateId(deposit);

        _verifySignal(deposit.chainId, height, deposit.from, id, accountProof, storageProof);

        super._processClaimDepositWithId(id, deposit);
    }

    function _verifySignal(
        uint64 chainId,
        uint256 height,
        address sender,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) internal view {
        bytes32 root = checkpointAt(height);
        (bool valid,) = LibSignal.verifySignal(root, chainId, sender, value, accountProof, storageProof);
        require(valid, SignalNotReceived(value));
    }
}
