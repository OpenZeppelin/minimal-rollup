// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../../libs/LibSignal.sol";
import {LibTrieProof} from "../../libs/LibTrieProof.sol";
import {ETHBridge} from "../ETHBridge.sol";
import {ISignalService} from "../ISignalService.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev Implementation of a secure cross-chain messaging system for broadcasting arbitrary data (i.e. signals).
///
/// The service defines the minimal logic to broadcast signals through `sendSignal` and verify them with
/// `verifySignal`.
contract SignalService is ISignalService, ETHBridge {
    using LibSignal for bytes32;
    using SafeCast for uint256;

    /// @dev Only required to be called on L1
    function sendSignal(bytes32 value) external returns (bytes32 signal) {
        return value.signal();
    }

    /// @dev Only required to be called on L2
    function verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 signal,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external pure {
        // TODO: Get the root from the trusted source
        bool isValid = _verifySignal(account, root, chainId, signal, accountProof, storageProof);
        require(isValid, "SignalService: invalid signal");
    }

    /// @dev Overrides ETHBridge.depositETH to add signaling functionality.
    function depositETH(uint64 chainId, address to, uint256 data) public payable override returns (bytes32 id) {
        id = super.depositETH(chainId, to, data);
        id.signal();
    }

    // CHECK: Should this function be non-reentrant?
    function claimDeposit(ETHDeposit memory deposit, bytes32 root, bytes[] memory accountProof, bytes[] memory proof)
        external
        override
        returns (bytes32 id)
    {
        id = _generateId(deposit);

        bool isValid = _verifySignal(address(this), root, deposit.chainId, id, accountProof, proof);
        require(isValid, "SignalService: invalid deposit");

        super._processClaimDepositWithId(id, deposit);
    }

    function _verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 signal,
        bytes[] memory accountProof,
        bytes[] memory stateProof
    ) internal pure returns (bool) {
        (bool valid,) = LibSignal.verifySignal(account, root, chainId, signal, accountProof, stateProof);
        return valid;
    }
}
