// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibTrieProof} from "./LibTrieProof.sol";
import {SlotDerivation} from "@openzeppelin/contracts/utils/SlotDerivation.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev Library for secure broadcasting cross-chain arbitrary data (i.e. signals).
///
/// Sending a signal consists of storing a `bytes32` value in a namespaced storage location to guarantee non-collision
/// slots derived by EVM languages such as Solidity or Vyper. Smart contracts utilizing this library will send signals
/// with the `sendSignal` function, allowing to generate a storage proof with an `eth_getProof` RPC call.
///
/// Later, on a destination chain the signal can be proven by providing the proof to `verifySignal` as long as the
/// state root is trusted (e.g. the L1 state root can made available on the L2 by the proposer).
library LibSignal {
    using SafeCast for uint256;
    using StorageSlot for bytes32;
    using SlotDerivation for string;

    /// @dev A signal was stored at a namespaced slot for the current `msg.sender` and `block.chainid`.
    function signalSent(bytes32 signal) internal view returns (bool) {
        return signalSent(signalSlot(block.chainid.toUint64(), msg.sender, signal));
    }

    /// @dev A signal was stored at a namespaced slot for the current `block.chainid`.
    function signalSent(address account, bytes32 signal) internal view returns (bool) {
        return signalSent(signalSlot(block.chainid.toUint64(), account, signal));
    }

    /// @dev A signal was stored at a namespaced slot. See `signalSlot`.
    function signalSent(uint64 chainId, address account, bytes32 signal) internal view returns (bool) {
        return signalSent(signalSlot(chainId, account, signal));
    }

    /// @dev A signal was stored at a namespaced `slot`. See `signalSlot`.
    function slotSignaled(bytes32 slot) internal view returns (bool) {
        return slot.getBytes32Slot().value != 0;
    }

    /// @dev Store a signal at a namespaced slot for the current `msg.sender` and `block.chainid`.
    function sendSignal(bytes32 signal) internal returns (bytes32) {
        return sendSignal(block.chainid.toUint64(), msg.sender, signal);
    }

    /// @dev Store a signal at a namespaced slot for the current `block.chainid`.
    function sendSignal(address account, bytes32 signal) internal returns (bytes32) {
        return sendSignal(block.chainid.toUint64(), account, signal);
    }

    /// @dev Store a signal at a namespaced slot. See `signalSlot`.
    function sendSignal(uint64 chainId, address account, bytes32 signal) internal returns (bytes32) {
        bytes32 slot = signalSlot(chainId, account, signal);
        slot.getBytes32Slot().value = signal;
        return slot;
    }

    /// @dev Returns the storage slot for a signal. Namespaced to the current `block.chainid` and `msg.sender`.
    function signalSlot(bytes32 signal) internal view returns (bytes32) {
        return signalSlot(msg.sender, signal);
    }

    /// @dev Returns the storage slot for a signal. Namespaced to the current `block.chainid`.
    function signalSlot(address account, bytes32 signal) internal view returns (bytes32) {
        return signalSlot(block.chainid.toUint64(), account, signal);
    }

    /// @dev Returns the storage slot for a signal.
    function signalSlot(uint64 chainId, address account, bytes32 signal) internal pure returns (bytes32) {
        return string(abi.encodePacked(chainId, account, signal)).erc7201Slot();
    }

    /// @dev Performs a storage proof on the `account`. User must ensure the `root` is trusted for the given `chainId`.
    function verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 signal,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) internal pure returns (bool valid, bytes32 storageRoot) {
        return LibTrieProof.verifyStorage(
            account, signalSlot(chainId, account, signal), signal, root, accountProof, storageProof
        );
    }
}
