// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {PreemptiveProvableAssertionsBase} from "./PreemptiveProvableAssertionsBase.sol";

struct L1Query {
    address destination;
    bytes callData;
}

/// @notice Preemptively assert the result of L1 queries at publication time
/// This can be used whenever the proposer can predict the result of those queries
///
/// The standard example is Nethermind's same-slot L1->L2 message passing
/// (https://ethresear.ch/t/same-slot-l1-l2-message-passing/21186)
/// Using the terminology from `PreemptiveProvableAssertionsBase`:
/// - a signal S is sent on L1 at time Y (between two publications)
/// - the signal service contract on L1 guarantees the message is permanent
/// - this means the proposer knows isSignalSent(S) will return true at any future time, including at publication time Z
/// - the proposer exposes that result on the L2 immediately so L2 users can act on the signal without waiting for the
/// next publication and anchor block.
///
/// @dev This contract assumes the queries will return a single word. We can generalise it if we decide to use this
/// mechanism.
/// @dev The queries will be called from the TaikoInbox contract, which will save a hash of the queries and results as a
/// publication attribute.
contract L1QueriesPublicationTime is PreemptiveProvableAssertionsBase {
    bytes32 constant DOMAIN_SEPARATOR = keccak256("L1L1QueriesPublicationTime");

    function assertL1QueryResults(L1Query[] calldata queries, uint256[] calldata results) public onlyAnchor {
        uint256 nQueries = queries.length;
        require(nQueries == results.length, "Inconsistent array lengths");
        bytes32 assertionId;
        for (uint256 i = 0; i < nQueries; i++) {
            assertionId = keccak256(abi.encode(DOMAIN_SEPARATOR, queries[i]));
            _assert(assertionId, results[i]);
        }
    }

    /// @param inboxAttribute the attribute computed in TaikoInbox (on L1). It indicates which queries were actually
    /// executed and their results
    function proveL1QueryResults(bytes32 inboxAttribute, bytes calldata proof) public onlyAnchor {
        require(inboxAttribute == keccak256(proof), "Proof does not correspond to executed queries");
        (L1Query[] memory queries, uint256[] memory results) = abi.decode(proof, (L1Query[], uint256[]));
        uint256 nQueries = queries.length; // We know this matches results.length because we validated inboxAttribute
        bytes32 assertionId;
        for (uint256 i = 0; i < nQueries; i++) {
            assertionId = keccak256(abi.encode(DOMAIN_SEPARATOR, queries[i]));
            require(value[assertionId] == results[i], "Result does not match assertion");
            _resolve(assertionId);
        }
    }

    /// @notice Can be called by any L2 contract to get the result of a preemptive L1 Query
    /// that will eventually be proven at publication time
    function getL1QueryResult(L1Query calldata query) public view returns (uint256) {
        bytes32 assertionId = keccak256(abi.encode(DOMAIN_SEPARATOR, query));
        require(exists[assertionId], "Query result has not been asserted");
        return value[assertionId];
    }
}
