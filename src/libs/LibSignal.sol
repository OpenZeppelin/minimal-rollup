// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibTrieProof} from "./LibTrieProof.sol";
import {SlotDerivation} from "@openzeppelin/contracts/utils/SlotDerivation.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @dev Library for secure broadcasting (i.e. signaling) cross-chain arbitrary data.
///
/// Signaling a value consists of storing a `bytes32` in a namespaced storage location to guarantee non-collision
/// slots derived by EVM languages such as Solidity or Vyper. Smart contracts utilizing this library will signal values
/// with the `signal` function, allowing to generate a storage proof with an `eth_getProof` RPC call.
///
/// Later, on a destination chain the signal can be proven by providing the proof to `verifySignal` as long as the
/// state root is trusted.
library LibSignal {
    using StorageSlot for bytes32;
    using SlotDerivation for string;

    /// @dev A `value` was signaled at a namespaced slot for the current `msg.sender` and `block.chainid`.
    function signaled(bytes32 value) internal view returns (bool) {
        return signaled(msg.sender, value);
    }

    /// @dev A `value` was signaled at a namespaced slot for the current `block.chainid`.
    function signaled(address account, bytes32 value) internal view returns (bool) {
        return signaled(uint64(block.chainid), account, value);
    }

    /// @dev A `value` was signaled at a namespaced slot. See `deriveSlot`.
    /// @dev This indicates whether the relevant storage slot is non-zero, which has two implications:
    /// - if a signal slot has an incorrect non-zero value, it will be "signaled" but `verifySignal` will fail
    /// - zero signals are not supported (but can be proven with `verifySignal`)
    function signaled(uint64 chainId, address account, bytes32 value) internal view returns (bool) {
        return deriveSlot(chainId, account, value).getBytes32Slot().value != 0;
    }

    /// @dev Signal a `value` at a namespaced slot for the current `msg.sender` and `block.chainid`.
    function signal(bytes32 value) internal returns (bytes32) {
        return signal(msg.sender, value);
    }

    /// @dev Signal a `value` at a namespaced slot for the current `block.chainid`.
    function signal(address account, bytes32 value) internal returns (bytes32) {
        return signal(uint64(block.chainid), account, value);
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
        return deriveSlot(uint64(block.chainid), account, value);
    }

    /// @dev Returns the storage slot for a signal.
    function deriveSlot(uint64 chainId, address account, bytes32 value) internal pure returns (bytes32) {
        return string(abi.encodePacked(chainId, account, value)).erc7201Slot();
    }

    /// @dev Performs a storage proof verification for a signal stored on the contract using this library
    /// @param root The state root from the source chain to verify against
    /// @param chainId The chain ID of the source chain where the signal was sent
    /// @param sender The address that originally sent the signal on the source chain
    /// @param value The signal value to verify
    /// @param accountProof Merkle proof for the contract's account against the state root
    /// @param storageProof Merkle proof for the derived storage slot against the account's storage root
    /// @return valid Boolean indicating whether the signal was successfully verified
    function verifySignal(
        bytes32 root,
        uint64 chainId,
        address sender,
        bytes32 value,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) internal view returns (bool valid) {
        (valid,) = LibTrieProof.verifyStorage(
            address(this), deriveSlot(chainId, sender, value), value, root, accountProof, storageProof
        );
    }
}
