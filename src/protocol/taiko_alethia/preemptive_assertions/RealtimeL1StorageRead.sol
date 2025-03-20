// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L1QueriesPublicationTime, L1Query} from "./L1QueriesPublicationTime.sol";
import {PreemptiveProvableAssertionsBase} from "./PreemptiveProvableAssertionsBase.sol";

struct L1StorageRef {
    uint256 blockNumber;
    address addr;
    uint256 slot;
}

/// @notice Assert the value of storage at arbitrary L1 blocks
/// This can be used for realtime L1 storage reads.
/// It can also be used to retrieve L1 storage that only existed between anchor blocks
///
/// Use the terminology from `PreemptiveProvableAssertionsBase`:
/// - an L1 block is posted at time Y (between two publications)
/// - this is public information but it is not reflected anywhere in L2 state
/// - the proposer asserts the value so L2 contracts can respond immediately
///
/// This can be used to retrieve any L1 storage the proposer knows. If they are running an archive node, this could be
/// any storage location from any block. If they are only running a full node, this must be within the last 256 L1
/// blocks. We assume there is an L1 block hash feed so any known value can be proven using only information available
/// on L1.
abstract contract RealtimeL1StorageRead is PreemptiveProvableAssertionsBase, L1QueriesPublicationTime {
    bytes32 constant STORAGE_DOMAIN_SEPARATOR = keccak256("RealtimeL1StorageRead");

    function getL1Storage(L1StorageRef memory ref) public view returns (uint256) {
        bytes32 assertionId = _assertionId(ref);
        require(exists[assertionId], "L1 Storage has not been asserted");
        return value[assertionId];
    }

    function assertL1Storage(L1StorageRef memory ref, uint256 value) public onlyAsserter {
        _assert(_assertionId(ref), value);
    }

    // The L1 block hash data feed is not implemented, so this is just a skeleton for explanation purposes
    function _proveL1Storage(L1StorageRef[] memory refs, uint256[] memory values, bytes memory proof) internal {
        // Query the latest value from the L1 block hash feed at publication time. For example, it could be a Merkle
        // root with all L1 block hashes, indexed by block number. It should be updated to cover all relevant blocks
        // before the publication is given to the TaikoInbox.
        // We use the same mechanism that any L2 contract can use to get the result of an L1 query
        // Since the result of this call will change every block, the sequence of events should be something like:
        // - an L1 block is published
        // - the asserter calls `assertL1Storage` for a given slot. At this point, they cannot construct the proof
        // because they do not know what `getLatestRoot()` will return, but they can still make the assertion.
        // - L2 contracts can call `getL1Storage` to act on this assertion.
        // - Before publication, the proposer will know what `getLatestRoot()` will return. At this point they make the
        // query assertion (i.e. call `assertL1QueryResult`)
        // - The final transaction in the block is `TaikoAnchor.endPublication`, which will call this function to
        // prove the storage, and the `_proveL1QueryResult` to prove the query. We can use the result of the query in
        // this storage proof because it has been asserted.
        L1Query memory query = L1Query({
            destination: address(0x1234), // the L1 blockhash data feed checkpoint tracker
            callData: abi.encodeWithSignature("getLatestRoot()")
        });
        bytes32 root = bytes32(getL1QueryResult(query));
        _verifyMultiMerkleProof(root, refs, values, proof);
    }

    function _verifyMultiMerkleProof(
        bytes32 root,
        L1StorageRef[] memory refs,
        uint256[] memory values,
        bytes memory proof
    ) internal {
        // TODO: Use the proof to validate
        // - all of the claimed L1 block hashes are in the root
        // - the values are in the correct slots for each of the L1 block hashes
    }

    function _assertionId(L1StorageRef memory ref) private pure returns (bytes32) {
        return keccak256(abi.encode(STORAGE_DOMAIN_SEPARATOR, ref));
    }
}
