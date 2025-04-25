// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "src/vendor/optimism/rlp/RLPReader.sol";
import "src/vendor/optimism/rlp/RLPWriter.sol";
import "src/vendor/optimism/trie/SecureMerkleTrie.sol";

/// @title Merkle-Patricia Trie Proof Verification
/// @custom:security-contact security@taiko.xyz
library LibTrieProof {
    /// @dev Retrieves account's storage root and verifies a storage slot within that root.
    /// @param accountProof Merkle proof for account state against global stateRoot
    /// @param storageProof Merkle proof for slot value against account's storageRoot
    /// @return valid True if both proofs verify successfully
    /// @return storageRoot The account's storage root retrieved with accountProof
    function verifyStorage(
        address account,
        bytes32 slot,
        bytes32 value,
        bytes32 stateRoot,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) internal pure returns (bool valid, bytes32 storageRoot) {
        RLPReader.RLPItem[] memory accountState =
            RLPReader.readList(SecureMerkleTrie.get(abi.encodePacked(account), accountProof, stateRoot));

        // Ethereum's State Trie state layout is a 4-item array of [nonce, balance, storageRoot, codeHash]
        // See https://ethereum.org/en/developers/docs/data-structures-and-encoding/patricia-merkle-trie/#state-trie
        storageRoot = bytes32(RLPReader.readBytes(accountState[2]));

        return (verifySlot(slot, value, storageRoot, storageProof), storageRoot);
    }

    /// @dev Verifies a value in Merkle-Patricia trie using inclusion proof
    /// @param key Slot/key to verify in the trie
    /// @param value Expected value at specified key
    /// @param storageRoot Root hash of the storage trie to verify against
    function verifySlot(bytes32 key, bytes32 value, bytes32 storageRoot, bytes[] memory proof)
        internal
        pure
        returns (bool valid)
    {
        return SecureMerkleTrie.verifyInclusionProof(
            bytes.concat(key), RLPWriter.writeUint(uint256(value)), proof, storageRoot
        );
    }
}
