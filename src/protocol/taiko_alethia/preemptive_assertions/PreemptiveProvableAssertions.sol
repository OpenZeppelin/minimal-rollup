// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L1QueriesPublicationTime, L1Query} from "./L1QueriesPublicationTime.sol";

import {PreemptiveProvableAssertionsBase} from "./PreemptiveProvableAssertionsBase.sol";
import {L1StorageRef, RealtimeL1StorageRead} from "./RealtimeL1StorageRead.sol";

contract PreemptiveProvableAssertions is L1QueriesPublicationTime, RealtimeL1StorageRead {
    constructor(address taikoAnchor) PreemptiveProvableAssertionsBase(taikoAnchor) {}

    function resolveAssertions(bytes32 attributesHash, bytes calldata proofs) external onlyAnchor {
        (
            bytes32[] memory attributeHashes,
            L1Query[] memory queries,
            uint256[] memory results,
            L1StorageRef[] memory refs,
            uint256[] memory values,
            bytes memory storageProof
        ) = abi.decode(proofs, (bytes32[], L1Query[], uint256[], L1StorageRef[], uint256[], bytes));

        // L1 Queries
        require(keccak256(abi.encode(attributeHashes)) == attributesHash, "Invalid attribute hashes");
        require(keccak256(abi.encode(queries, results)) == attributeHashes[3], "Invalid queries or results");
        _proveL1QueryResults(queries, results);

        // L1 Storage
        _proveL1Storage(refs, values, storageProof);

        require(nAssertions == 0, "Some assertions were not resolved");
    }
}
