// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibTrieProof} from "../libs/LibTrieProof.sol";
import {ISignalService} from "./ISignalService.sol";

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev Implementation of a secure cross-chain messaging system for broadcasting arbitrary data (i.e. signals).
///
/// The service defines the minimal logic to broadcast signals through `sendSignal` and verify them with
/// `verifySignal`. Storing the verification status is up to the accounts that interact with this service.
///
/// For cases when the signal cannot verified immediately (e.g., a storage proof of the L1 state in the L2),
/// the contract defines a receiver role that must be implemented in `_checkReceiver`. Consider implementing
/// an access control mechanism for this purpose.
abstract contract SignalService is ISignalService {
    using SafeCast for uint256;
    using StorageSlot for bytes32;
    using LibTrieProof for address;

    mapping(bytes32 signal => bool) private _receivedSignals;

    /// @dev Only an authorized receiver.
    modifier onlyReceiver() {
        _checkReceiver(msg.sender);
        _;
    }

    /// @inheritdoc ISignalService
    function signalReceived(bytes32 slot) public view virtual returns (bool received) {
        return _receivedSignals[slot];
    }

    /// @inheritdoc ISignalService
    function signalSlot(uint64 chainId, address account, bytes32 signal) public pure virtual returns (bytes32 slot) {
        bytes32 namespaceId = keccak256(abi.encodePacked(chainId, account, signal));
        return keccak256(abi.encode(uint256(namespaceId) - 1)) & ~bytes32(uint256(0xff));
    }

    /// @inheritdoc ISignalService
    function sendSignal(bytes32 signal) external virtual returns (bytes32 slot) {
        return _sendSignal(msg.sender, signal);
    }

    /// @inheritdoc ISignalService
    function receiveSignal(bytes32[] calldata slots) external virtual onlyReceiver {
        _receiveSignal(slots);
    }

    /// @inheritdoc ISignalService
    function verifySignal(
        address signalService,
        bytes32 root,
        uint64 chainId,
        bytes32 signal,
        bytes[] calldata accountProof,
        bytes[] calldata storageProof
    ) external pure virtual returns (bool valid, bytes32 storageRoot) {
        return signalService.verifyStorage(
            root, signalSlot(chainId, signalService, signal), signal, accountProof, storageProof
        );
    }

    /// @dev Must revert if the caller is not an authorized receiver.
    function _checkReceiver(address caller) internal virtual;

    function _sendSignal(address account, bytes32 signal) internal virtual returns (bytes32 slot) {
        slot = signalSlot(block.chainid.toUint64(), account, signal);
        slot.getBytes32Slot().value = signal;
        emit SignalSent(account, signal);
        return slot;
    }

    function _receiveSignal(bytes32[] calldata slots) internal virtual {
        for (uint256 i; i < slots.length; ++i) {
            _receivedSignals[slots[i]] = true;
        }
        emit SignalsReceived(slots);
    }
}
