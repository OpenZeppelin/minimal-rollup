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
/// state root is trusted.
library LibSignal {
    using StorageSlot for bytes32;
    using SlotDerivation for string;
    using SafeCast for uint256;

    /// @dev A `value` was signaled at a namespaced slot for the current `msg.sender`.
    function signaled(bytes32 value) internal view returns (bool) {
        return signaled(value, msg.sender);
    }

    /// @dev A `value` was signaled at a namespaced slot. See `deriveSlot`.
    /// @dev This indicates whether the relevant storage slot is non-zero, which has two implications:
    /// - if a signal slot has an incorrect non-zero value, it will be "signaled" but `verifySignal` will fail
    /// - zero signals are not supported (but can be proven with `verifySignal`)
    function signaled(bytes32 value, address account) internal view returns (bool) {
        return deriveSlot(value, account).getBytes32Slot().value != 0;
    }

    /// @dev Signal a `value` at a namespaced slot for the current `msg.sender`
    function signal(bytes32 value) internal returns (bytes32) {
        return signal(value, msg.sender);
    }

    /// @dev Signal a `value` at a namespaced slot. See `deriveSlot`.
    function signal(bytes32 value, address account) internal returns (bytes32) {
        bytes32 slot = deriveSlot(value, account);
        slot.getBytes32Slot().value = value;
        return slot;
    }

    /// @dev Returns the storage slot for a signal. Namespaced to the msg.sender and value.
    function deriveSlot(bytes32 value) internal view returns (bytes32) {
        return deriveSlot(value, msg.sender);
    }

    /// @dev Returns the storage slot for a signal. Namespaced to the current account and value.
    function deriveSlot(bytes32 value, address account) internal pure returns (bytes32) {
        return string(abi.encodePacked(account, value)).erc7201Slot();
    }

    /// @dev Performs a storage proof verification for a signal stored on the contract using this library
    /// @param value The signal value to verify
    /// @param root The state root from the source chain to verify against
    /// @param sender The address that originally sent the signal on the source chain
    /// @param accountProof Merkle proof for the contract's account against the state root
    /// @param storageProof Merkle proof for the derived storage slot against the account's storage root
    /// @return valid Boolean indicating whether the signal was successfully verified
    function verifySignal(
        bytes32 value,
        bytes32 root,
        address sender,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) internal view returns (bool valid) {
        (valid,) = LibTrieProof.verifyStorage(
            address(this), deriveSlot(value, sender), value, root, accountProof, storageProof
        );
    }

    /// @dev Verifies a value in Merkle-Patricia trie using inclusion proof
    /// @param value The signal value to verify
    /// @param root The state root from the source chain to verify against
    /// @param sender The address that originally sent the signal on the source chain
    /// @param stateProof Merkle proof for the derived storage slot against the account's storage root
    /// @return valid Boolean indicating whether the signal was successfully verified
    function verifySignal(bytes32 value, bytes32 root, address sender, bytes[] memory stateProof)
        internal
        pure
        returns (bool valid)
    {
        valid = LibTrieProof.verifyState(deriveSlot(value, sender), value, root, stateProof);
    }
}
