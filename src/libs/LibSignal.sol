// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibTrieProof} from "./LibTrieProof.sol";
import {SlotDerivation} from "@openzeppelin/contracts/utils/SlotDerivation.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev Library for secure broadcasting (i.e. signaling) cross-chain arbitrary data.
///
/// Signaling a value consists of storing a `bytes32` in a namespaced storage location to guarantee non-collision
/// slots derived by EVM languages such as Solidity or Vyper. Smart contracts utilizing this library will signal values
/// with the `signal` function, allowing to generate a storage proof with an `eth_getProof` RPC call.
///
/// Later, on a destination chain the signal can be proven by providing the proof to `verifySignal` as long as the
/// state root is trusted (e.g. the L1 state root can made available on the L2 by the proposer).
library LibSignal {
    using SafeCast for uint256;
    using StorageSlot for bytes32;
    using SlotDerivation for string;

    /// @dev A `value` was signaled at a namespaced slot for the current `msg.sender` and `block.chainid`.
    function signaled(bytes32 value) internal view returns (bool) {
        return signaled(msg.sender, value);
    }

    /// @dev A `value` was signaled at a namespaced slot for the current `block.chainid`.
    function signaled(address account, bytes32 value) internal view returns (bool) {
        return signaled(block.chainid.toUint64(), account, value);
    }

    /// @dev A `value` was signaled at a namespaced slot. See `deriveSlot`.
    function signaled(uint64 chainId, address account, bytes32 value) internal view returns (bool) {
        return deriveSlot(chainId, account, value).getBytes32Slot().value != 0;
    }

    /// @dev Signal a `value` at a namespaced slot for the current `msg.sender` and `block.chainid`.
    function signal(bytes32 value) internal returns (bytes32) {
        return signal(msg.sender, value);
    }

    /// @dev Signal a `value` at a namespaced slot for the current `block.chainid`.
    function signal(address account, bytes32 value) internal returns (bytes32) {
        return signal(block.chainid.toUint64(), account, value);
    }

    /// @dev Signal a `value` at a namespaced slot. See `deriveSlot`.
    function signal(uint64 chainId, address account, bytes32 value) internal returns (bytes32) {
        bytes32 slot = deriveSlot(chainId, account, value);
        slot.getBytes32Slot().value = value;
        return slot;
    }

    /// @dev Returns the storage slot for a signal. Namespaced to the current `block.chainid` and `msg.sender`.
    function deriveSlot(bytes32 value) internal view returns (bytes32) {
        return deriveSlot(msg.sender, value);
    }

    /// @dev Returns the storage slot for a signal. Namespaced to the current `block.chainid`.
    function deriveSlot(address account, bytes32 value) internal view returns (bytes32) {
        return deriveSlot(block.chainid.toUint64(), account, value);
    }

    /// @dev Returns the storage slot for a signal.
    function deriveSlot(uint64 chainId, address account, bytes32 value) internal pure returns (bytes32) {
        return string(abi.encodePacked(chainId, account, value)).erc7201Slot();
    }

    /// @dev Performs a storage proof on the `account`. User must ensure the `root` is trusted for the given `chainId`.
    function verifySignal(
        address account,
        bytes32 root,
        uint64 chainId,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) internal pure returns (bool valid, bytes32 storageRoot) {
        return LibTrieProof.verifyStorage(
            account, deriveSlot(chainId, account, value), value, root, accountProof, storageProof
        );
    }
}
