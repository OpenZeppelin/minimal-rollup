// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../../libs/LibSignal.sol";
import {LibTrieProof} from "../../libs/LibTrieProof.sol";
import {ETHBridge} from "../ETHBridge.sol";
import {ISignalService} from "../ISignalService.sol";

/// @dev Implementation of a secure cross-chain messaging system for broadcasting arbitrary data (i.e. signals).
///
/// The service defines the minimal logic to broadcast signals through `sendSignal` and verify them with
/// `verifySignal`. The service is designed to be used in conjunction with the `ETHBridge` contract to
/// enable cross-chain communication.
contract SignalService is ISignalService, ETHBridge {
    using LibSignal for bytes32;

    /// @inheritdoc ISignalService
    function sendSignal(bytes32 value) external returns (bytes32 signal) {
        signal = value.signal();
        emit SignalSent(signal);
    }

    /// @inheritdoc ISignalService
    function isSignalSent(bytes32 signal) external view returns (bool) {
        // This will return `false` when the signal itself is 0
        return signal.signaled();
    }

    /// @inheritdoc ISignalService
    function verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 signal,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external {
        // TODO: Get the root from the trusted source
        _verifySignal(account, root, chainId, signal, accountProof, storageProof);

        emit SignalVerified(signal, chainId, root);
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

        _verifySignal(address(this), root, deposit.chainId, id, accountProof, proof);

        super._processClaimDepositWithId(id, deposit);
    }

    function _verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 signal,
        bytes[] memory accountProof,
        bytes[] memory stateProof
    ) internal pure {
        (bool valid,) = LibSignal.verifySignal(account, root, chainId, signal, accountProof, stateProof);
        require(valid, SignalNotReceived(signal, root));
    }
}
