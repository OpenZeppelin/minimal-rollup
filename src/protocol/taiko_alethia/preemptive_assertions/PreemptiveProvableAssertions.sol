// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L1QueriesPublicationTime, L1Query} from "./L1QueriesPublicationTime.sol";
import {PreemptiveProvableAssertionsBase} from "./PreemptiveProvableAssertionsBase.sol";

contract PreemptiveProvableAssertions is L1QueriesPublicationTime {
    constructor(address taikoAnchor) PreemptiveProvableAssertionsBase(taikoAnchor) {}

    function resolveAssertions(bytes32 attributesHash, bytes calldata proofs) external onlyAnchor {
        // retrieve the L1_QUERIES attribute
        (bytes32[] memory attributeHashes, L1Query[] memory queries, uint256[] memory results) =
            abi.decode(proofs, (bytes32[], L1Query[], uint256[]));
        require(keccak256(abi.encode(attributeHashes)) == attributesHash, "Invalid attribute hashes");
        require(keccak256(abi.encode(queries, results)) == attributeHashes[3], "Invalid queries or results");

        _proveL1QueryResults(queries, results);

        require(nAssertions == 0, "Some assertions were not resolved");
    }
}
