// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../libs/LibSignal.sol";
import {LibTrieProof} from "../libs/LibTrieProof.sol";
import {CommitmentStore} from "./CommitmentStore.sol";
import {ETHBridge} from "./ETHBridge.sol";
import {ISignalService} from "./ISignalService.sol";

/// @dev SignalService combines secure cross-chain messaging with native token bridging.
///
/// This contract allows sending arbitrary data as signals via `sendSignal`, verifying signals from other chains using
/// `verifySignal`, and bridging native ETH with built-in signal generation and verification. It integrates:
/// - `CommitmentStore` to access trusted state roots,
/// - `ETHBridge` for native ETH bridging with deposit and claim flows,
/// - `LibSignal` for signal hashing, storage, and verification logic.
///
/// Signals stored can not be deleted and can be verified multiple times.
contract SignalService is ISignalService, ETHBridge, CommitmentStore {
    using LibSignal for bytes32;

    constructor(address _rollupOperator) CommitmentStore(_rollupOperator) {}

    /// @inheritdoc ISignalService
    function sendSignal(bytes32 value) external returns (bytes32 slot) {
        slot = value.signal();
        emit SignalSent(msg.sender, value);
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
    function depositETH(uint64 chainId, address to, bytes memory data) public payable override returns (bytes32 id) {
        id = super.depositETH(chainId, to, data);
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
        bytes32 root = commitmentAt(height);
        bool valid = LibSignal.verifySignal(root, chainId, sender, value, accountProof, storageProof);
        require(valid, SignalNotReceived(chainId, value));
    }
}
