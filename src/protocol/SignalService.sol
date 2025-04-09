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
    function verifySignal(uint256 height, address sender, bytes32 value, bytes memory proof) external {
        _verifySignal(height, sender, value, proof);
        emit SignalVerified(sender, value);
    }

    /// @dev Overrides ETHBridge.depositETH to add signaling functionality.
    function deposit(address to, bytes memory data) public payable override returns (bytes32 id) {
        id = super.deposit(to, data);
        id.signal();
    }

    // CHECK: Should this function be non-reentrant?
    /// @inheritdoc ETHBridge
    /// @dev Overrides ETHBridge.claimDeposit to add signal verification logic.
    function claimDeposit(ETHDeposit memory ethDeposit, uint256 height, bytes memory proof)
        external
        override
        returns (bytes32 id)
    {
        // TODO: Maybe this function should accept a depositID ?
        // maybe slightly more gas efficient
        // Also as of now there is no way to reconstruct the ethdeposit struct (uses a hidden global nonce)
        id = _generateId(ethDeposit);

        _verifySignal(height, ethDeposit.from, id, proof);

        super._processClaimDepositWithId(id, ethDeposit);
    }

    function _verifySignal(uint256 height, address sender, bytes32 value, bytes memory proof) internal view virtual {
        // TODO: commitmentAt(height) might not be the 'state root' of the chain
        // For now it could be the block hash or other hashed value
        // further work is needed to ensure we get the 'state root' of the chain
        bytes32 root = commitmentAt(height);

        SignalProof memory signalProof = abi.decode(proof, (SignalProof));
        bytes[] memory accountProof = signalProof.accountProof;
        bytes[] memory storageProof = signalProof.storageProof;
        bool valid;
        // If the account proof is empty we assume `root` is the root of the signal tree
        if (accountProof.length == 0) {
            // Only verifies a state proof not full storage proof
            valid = LibSignal.verifySignal(root, sender, value, storageProof);
            require(valid, SignalNotReceived(value));
            return;
        }
        valid = LibSignal.verifySignal(root, sender, value, accountProof, storageProof);
        require(valid, SignalNotReceived(value));
    }
}
