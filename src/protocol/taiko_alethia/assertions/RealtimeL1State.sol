// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {TaikoInbox} from "../TaikoInbox.sol";

import {Asserter} from "./Asserter.sol";
import {CalledByAnchor} from "./CalledByAnchor.sol";
import {LibBlockHeader} from "src/libs/LibBlockHeader.sol";

contract RealtimeL1State is Asserter {
    error InconsistentBlockHashAssertions();
    error AnchorBlockHashNotAsserted();

    constructor(address _anchor, address _preemptiveAssertions)
        CalledByAnchor(_anchor)
        Asserter(_preemptiveAssertions)
    {}

    function assertL1Header(uint256 l1BlockNumber, LibBlockHeader.BlockHeader memory header) external {
        bytes32 blockHash = keccak256(abi.encode(header)); // TODO: confirm the hash encoding

        // create different assertions for the relevant fields so we can handle them separately
        preemptiveAssertions.createAssertion(_blockHashKey(l1BlockNumber), blockHash);
        preemptiveAssertions.createAssertion(_parentHashKey(l1BlockNumber), header.parentHash);
        preemptiveAssertions.createAssertion(_stateRootKey(l1BlockNumber), header.stateRoot);
    }

    /// @dev This simply ensures that this assertions is consistent with the next block header assertion,
    /// which will need to be resolved at some point.
    function resolveUsingNextAssertion(uint256 l1BlockNumber) external {
        bytes32 blockHashFromHeader = preemptiveAssertions.getAssertion(_blockHashKey(l1BlockNumber));
        bytes32 blockHashFromNextHeader = preemptiveAssertions.getAssertion(_parentHashKey(l1BlockNumber + 1));
        require(blockHashFromHeader == blockHashFromNextHeader, InconsistentBlockHashAssertions());
        _clearAssertions(l1BlockNumber);
    }

    function _resolve(bytes32[] calldata attributeHashes, bytes calldata encodedMetadata) internal override {
        require(attributeHashes[0] == keccak256(encodedMetadata), "Invalid metadata");
        (TaikoInbox.Metadata memory metadata) = abi.decode(encodedMetadata, (TaikoInbox.Metadata));

        bytes32 assertedAnchorBlockHash = preemptiveAssertions.getAssertion(_blockHashKey(metadata.anchorBlockId));
        require(assertedAnchorBlockHash == metadata.anchorBlockHash, AnchorBlockHashNotAsserted());
        _clearAssertions(metadata.anchorBlockId);
    }

    function _clearAssertions(uint256 l1BlockNumber) internal {
        preemptiveAssertions.removeAssertion(_blockHashKey(l1BlockNumber));
        preemptiveAssertions.removeAssertion(_parentHashKey(l1BlockNumber));
        preemptiveAssertions.setProven(_stateRootKey(l1BlockNumber));
    }

    function _blockHashKey(uint256 l1BlockNumber) internal pure returns (bytes32) {
        return _key(l1BlockNumber, LibBlockHeader.BLOCK_HASH);
    }

    function _parentHashKey(uint256 l1BlockNumber) internal pure returns (bytes32) {
        return _key(l1BlockNumber, LibBlockHeader.PARENT_HASH);
    }

    function _stateRootKey(uint256 l1BlockNumber) internal pure returns (bytes32) {
        return _key(l1BlockNumber, LibBlockHeader.STATE_ROOT);
    }

    function _key(uint256 l1BlockNumber, bytes32 field) internal pure returns (bytes32) {
        return keccak256(abi.encode(l1BlockNumber, field));
    }
}
