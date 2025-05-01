// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SlotDerivation} from "@openzeppelin/contracts/utils/SlotDerivation.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {LibTrieProof} from "@vendor/taiko/LibTrieProof.sol";

/// @dev Library for secure broadcasting (i.e. signaling) cross-chain arbitrary data.
library LibSignal {
    using StorageSlot for bytes32;
    using SlotDerivation for string;
    using SafeCast for uint256;

    /// @dev A `value` was signaled at a namespaced slot for the current `msg.sender`.
    function signaled(bytes32 value) internal view returns (bool) {
        return signaled(value, msg.sender);
    }

    /// @dev A `value` was signaled at a namespaced slot. See `deriveSlot`.
    function signaled(bytes32 value, address account) internal view returns (bool) {
        bytes32 slot = deriveSlot(value, account);
        return slot.getBooleanSlot().value == true;
    }

    /// @dev Signal a `value` at a namespaced slot for the current `msg.sender` and namespace.
    function signal(bytes32 value) internal returns (bytes32) {
        return signal(value, msg.sender);
    }

    /// @dev Signal a `value` at a namespaced slot. See `deriveSlot`.
    function signal(bytes32 value, address account) internal returns (bytes32) {
        bytes32 slot = deriveSlot(value, account);
        slot.getBooleanSlot().value = true;
        return slot;
    }

    /// @dev Returns the storage slot for a signal. Namespaced to the msg.sender and value
    function deriveSlot(bytes32 value) internal view returns (bytes32) {
        return deriveSlot(value, msg.sender);
    }

    /// @dev Returns the storage slot for a signal. Namespaced to the current account and value.
    function deriveSlot(bytes32 value, address account) internal pure returns (bytes32) {
        return string(abi.encodePacked(value, account)).erc7201Slot();
    }

    /// @dev Performs a storage proof verification for a signal stored on the contract using this library
    /// @param value The signal value to verify
    /// @param sender The address that originally sent the signal on the source chain
    /// @param root The state root or storage root from the source chain to verify against
    /// @param accountProof Merkle proof for the contract's account against the state root. Empty if we are using a
    /// storage root.
    /// @param storageProof Merkle proof for the derived storage slot against the account's storage root
    function verifySignal(
        bytes32 value,
        address sender,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) internal view {
        bytes32 encodedBool = bytes32(uint256(1));
        LibTrieProof.verifyMerkleProof(
            root, address(this), deriveSlot(value, sender), encodedBool, accountProof, storageProof
        );
    }
}
