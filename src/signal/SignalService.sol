// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../libs/LibSignal.sol";
import {LibTrieProof} from "../libs/LibTrieProof.sol";
import {ISignalService} from "./ISignalService.sol";

/// @dev Implementation of a secure cross-chain messaging system for broadcasting arbitrary data (i.e. signals).
///
/// The service defines the minimal logic to broadcast signals through `sendSignal` and verify them with
/// `verifySignal`. Storing the verification status is up to the accounts that interact with this service.
contract SignalService is ISignalService {
    using LibSignal for bytes32;

    /// @dev Only required to be called on L1
    function sendSignal(bytes32 value) external returns (bytes32 signal) {
        return value.signal();
    }

    /// @dev Only required to be called on L2
    function verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external pure {
        // TODO: Get the root from the trusted source
        (bool valid,) = LibSignal.verifySignal(account, root, chainId, value, accountProof, storageProof);
        require(valid, "SignalService: invalid signal");
    }
}
