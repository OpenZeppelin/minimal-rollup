// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {PreemptiveProvableAssertionsBase} from "./PreemptiveProvableAssertionsBase.sol";

struct FutureL2Query {
    uint256 blockNumber;
    address destination;
    bytes callData;
}

/// @notice Preemptively assert the result of an L2 query at some future block before publication
/// This can be used to simplify interdependent conditional transactions
///
/// Consider two L2 transactions published before future block F where:
/// - Address A sends token0 to Address B if token1.balanceOf(A) will be greater than some threshold at block F
/// - Address B sends token1 to Address A if token0.balanceOf(B) will be greater than some threshold at block F
///
/// The proposer can see both transactions and decide to include them both.
/// The proposer makes both assertions (that the balances will increase by the required amounts by block F)
/// so the transactions succeed.
abstract contract L2QueryFutureBlock is PreemptiveProvableAssertionsBase {
    bytes32 constant FUTURE_QUERY_DOMAIN_SEPARATOR = keccak256("L2QueryFutureBlock");

    /// @notice Can be called by any L2 contract to get the result of a preemptive L2 Query
    /// that will eventually be proven at the future block
    function getL2QueryResult(FutureL2Query memory query) public view returns (uint256) {
        bytes32 assertionId = _assertionId(query);
        require(exists[assertionId], "Query result has not been asserted");
        return value[assertionId];
    }

    function assertFutureL2QueryResult(FutureL2Query memory query, uint256 result) public onlyAsserter {
        _assert(_assertionId(query), result);
    }

    function proveFutureL2QueryResult(FutureL2Query memory query) public {
        // since this executes on L2, we can just check the result directly in the future block
        // we assume it is a public function accessible to this contract, that it returns a uint256, and there is no
        // need for access control (to prevent multiple calls at maliciously chosen times) but we can generalise the
        // idea if desired
        require(block.number == query.blockNumber, "Incorrect L2 block");
        bytes32 assertionId = _assertionId(query);

        (bool success, bytes memory returndata) = query.destination.call(query.callData);
        require(success, "Query failed");
        uint256 result = abi.decode(returndata, (uint256));

        require(value[assertionId] == result, "Result does not match assertion");
        _resolve(assertionId);
    }

    function _assertionId(FutureL2Query memory query) private pure returns (bytes32) {
        return keccak256(abi.encode(FUTURE_QUERY_DOMAIN_SEPARATOR, query));
    }
}
