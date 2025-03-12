// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibSignal} from "../libs/LibSignal.sol";
import {ISignalService} from "./ISignalService.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @title SignalService
/// @notice A minimal implementation of a signal service using LibSignal.
contract SignalService is ISignalService {
    using LibSignal for bytes32;
    using StorageSlot for bytes32;

    address internal _rollup;

    mapping(bytes32 signal => bool isReceived) internal _receivedSignals;

    constructor(address rollup_) {
        _rollup = rollup_;
    }

    modifier onlyRollup() {
        require(msg.sender == _rollup, CallerNotAuthorised());
        _;
    }

    /// @dev Only required to be called on L1
    function sendSignal(bytes32 value) external returns (bytes32 signal) {
        signal = value.signal();
        emit SignalSent(signal);
    }

    /// @dev Only required to be called on L1
    function sendFastSignal(bytes32 value) external returns (bytes32 signal) {
        signal = value.signal();
        emit FastSignalSent(signal);
    }

    /// @dev Only required to be called on L2
    function receiveSignals(bytes32[] calldata signalSlots) external onlyRollup {
        for (uint256 i; i < signalSlots.length; ++i) {
            _receivedSignals[signalSlots[i]] = true;
        }
        emit SignalsReceived(signalSlots);
    }

    /// @dev Only required to be called on L2
    function verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external view {
        if (accountProof.length == 0) {
            require(_receivedSignals[LibSignal.deriveSlot(chainId, account, value)], SignalNotReceived());
            return;
        }

        (bool valid,) = LibSignal.verifySignal(account, root, chainId, value, accountProof, storageProof);
        require(valid, SignalNotReceived());
    }

    /// @dev Only required to be called on L1
    function isSignalSent(bytes32 signal) external view returns (bool) {
        // This will return `false` when the signal itself is 0
        return signal.getBytes32Slot().value != 0;
    }
}
