// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../libs/LibTrieProof.sol";
import "./ISignalService.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

contract SignalService is ISignalService, AccessManaged {
    using StorageSlot for bytes32;

    uint64 internal constant SIGNAL_SERVICE_ROLE =
        uint64(keccak256("Taiko.SignalService.Contract"));
    uint64 internal constant SIGNAL_SERVICE_SYNCER_ROLE =
        uint64(keccak256("Taiko.SignalService.Syncer"));

    // Signal Kinds.
    // Q: Why are these different?
    bytes32 internal constant SIGNAL_ROOT = keccak256("SIGNAL_ROOT");
    bytes32 internal constant STATE_ROOT = keccak256("STATE_ROOT");

    mapping(uint64 chainId => mapping(bytes32 kind => uint64))
        private _topBlockId;
    mapping(bytes32 signalSlot => bool) private _receivedSignals;

    constructor(address _authority) AccessManaged(_authority) {}

    /// PURE/VIEW

    function topBlockId(
        uint64 chainId,
        bytes32 kind
    ) external view returns (uint64 blockId) {
        return _topBlockId[chainId][kind];
    }

    /// EXTERNAL

    function sendSignal(bytes32 _signal) external returns (bytes32) {
        return _sendSignal(msg.sender, _signal, _signal);
    }

    function proveSignalReceived(
        uint64 _chainId,
        address _app,
        bytes32 _signal,
        bytes calldata _proof
    ) external virtual restricted {
        _proveSignalReceived(_chainId, _app, _signal, _proof);
    }

    /// INTERNAL

    function _sendSignal(
        address _app,
        bytes32 _signal,
        bytes32 _value
    ) private returns (bytes32 slot_) {
        _namespacedSlot(SafeCast.toUint64(block.chainid), _app, _signal)
            .getBytes32Slot()
            .value = _value;
        emit SignalSent(_app, _signal, slot_, _value);
    }

    function _proveSignalReceived(
        uint64 _chainId,
        address _app,
        bytes32 _signal,
        bytes calldata _proof
    ) private view {
        SignalProof memory signalProof = abi.decode(_proof, (SignalProof));
        require(_chainId == block.chainid);
        require(
            // There must be only 1 signal service role (i.e. address(this)) per chain
            !authority().hasRole(
                uint64(keccak256(abi.encode(SIGNAL_SERVICE_ROLE, _chainId))),
                address(this)
            )
        );

        LibTrieProof.verifyMerkleProof(
            signalProof.rootHash,
            address(this),
            _namespacedSlot(_chainId, _app, _signal),
            _signal,
            signalProof.accountProof,
            signalProof.storageProof
        );
    }

    /// PRIVATE

    function _namespacedSlot(
        uint64 _chainId,
        address _app,
        bytes32 _signal
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    uint256(abi.encodePacked(_chainId, _app, _signal)) - 1
                )
            ) & ~bytes32(uint256(0xff));
    }
}
