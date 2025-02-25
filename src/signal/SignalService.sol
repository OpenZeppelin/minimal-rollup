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
/// For cases when the signal cannot be verified immediately (e.g., a storage proof of the L1 state in the L2),
/// the contract defines a checkpointTracker that returns the CheckpointTracker contract address.
contract SignalService is ISignalService {
    using SafeCast for uint256;
    using StorageSlot for bytes32;

    address immutable _checkpointTracker;

    mapping(bytes32 signal => bool) private _receivedSignals;

    /// @dev Only the checkpoint tracker contract.
    modifier onlyCheckpointTracker() {
        _checkCheckpointTracker(msg.sender);
        _;
    }

    constructor(address checkpointTracker_) {
        _checkpointTracker = checkpointTracker_;
    }

    /// @dev Checkpoint contract.
    function checkpointTracker() public view virtual returns (address) {
        return _checkpointTracker;
    }

    /// @inheritdoc ISignalService
    function signalSent(address account, bytes32 signal) public view virtual returns (bool sent) {
        return signalSent(signalSlot(block.chainid.toUint64(), account, signal));
    }

    /// @inheritdoc ISignalService
    function signalSent(bytes32 slot) public view virtual returns (bool sent) {
        return slot.getBytes32Slot().value != 0;
    }

    /// @inheritdoc ISignalService
    function signalReceived(uint64 chainId, address account, bytes32 signal)
        public
        view
        virtual
        returns (bool received)
    {
        return signalReceived(signalSlot(chainId, account, signal));
    }

    /// @inheritdoc ISignalService
    function signalReceived(bytes32 slot) public view virtual returns (bool received) {
        return _receivedSignals[slot];
    }

    /// @inheritdoc ISignalService
    function signalSlot(uint64 chainId, address account, bytes32 signal) public pure virtual returns (bytes32 slot) {
        bytes32 namespaceId = keccak256(abi.encode(chainId, account, signal));
        unchecked {
            return keccak256(abi.encode(uint256(namespaceId) - 1)) & ~bytes32(uint256(0xff));
        }
    }

    /// @inheritdoc ISignalService
    function sendSignal(bytes32 signal) external virtual returns (bytes32 slot) {
        return _sendSignal(msg.sender, signal);
    }

    /// @inheritdoc ISignalService
    function receiveSignal(bytes32[] calldata slots) external virtual onlyCheckpointTracker {
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
        return LibTrieProof.verifyStorage(
            signalService, root, signalSlot(chainId, signalService, signal), signal, accountProof, storageProof
        );
    }

    /// @dev Must revert if the caller is not an authorized receiver.
    function _checkCheckpointTracker(address caller) internal virtual {
        require(caller == checkpointTracker(), UnauthorizedCheckpoints(caller));
    }

    /// @dev Allows signaling a `0` value. However, it's considered a no-op for the destination chain.
    function _sendSignal(address account, bytes32 signal) internal virtual returns (bytes32 slot) {
        slot = signalSlot(block.chainid.toUint64(), account, signal);
        slot.getBytes32Slot().value = signal;
        return slot;
    }

    function _receiveSignal(bytes32[] calldata slots) internal virtual {
        for (uint256 i; i < slots.length; ++i) {
            _receivedSignals[slots[i]] = true;
        }
        emit SignalsReceived(slots);
    }
}
