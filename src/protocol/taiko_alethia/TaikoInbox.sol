// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

import {IDelayedInclusionStore} from "../IDelayedInclusionStore.sol";
import {IPublicationFeed} from "../IPublicationFeed.sol";
import {DelayedInclusionStore} from "./DelayedInclusionStore.sol";

import {IInbox} from "../IInbox.sol";
import {ILookahead} from "../ILookahead.sol";
import {IProposerFees} from "../IProposerFees.sol";
import {CallSpecification} from "./assertions/PublicationTimeCall.sol";

contract TaikoInbox is IInbox, DelayedInclusionStore {
    struct Metadata {
        uint256 anchorBlockId;
        bytes32 anchorBlockHash;
        bool isDelayedInclusion;
    }

    IPublicationFeed public immutable publicationFeed;
    ILookahead public immutable lookahead;
    IProposerFees public immutable proposerFees;

    uint256 public immutable maxAnchorBlockIdOffset;

    uint64 public lastPublicationId;

    // attributes associated with the publication
    uint256 private constant METADATA = 0;
    uint256 private constant LAST_PUBLICATION = 1;
    uint256 private constant BLOB_REFERENCE = 2;
    uint256 private constant L1_CALLS = 3;

    constructor(
        address _publicationFeed,
        address _lookahead,
        address _blobRefRegistry,
        uint256 _maxAnchorBlockIdOffset,
        address _proposerFees,
        uint256 _inclusionDelay
    ) DelayedInclusionStore(_inclusionDelay, _blobRefRegistry) {
        publicationFeed = IPublicationFeed(_publicationFeed);
        lookahead = ILookahead(_lookahead);
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
        proposerFees = IProposerFees(_proposerFees);
    }

    function publish(uint256 nBlobs, uint64 anchorBlockId, CallSpecification[] calldata callSpecs) external {
        if (address(lookahead) != address(0)) {
            require(lookahead.isCurrentPreconfer(msg.sender), "not current preconfer");
        }

        uint256 _lastPublicationId = lastPublicationId;

        // Build the attribute for the anchor transaction inputs
        require(anchorBlockId >= block.number - maxAnchorBlockIdOffset, "anchorBlockId too old");

        Metadata memory metadata = Metadata({
            anchorBlockId: anchorBlockId,
            anchorBlockHash: blockhash(anchorBlockId),
            isDelayedInclusion: false
        });
        require(metadata.anchorBlockHash != 0, "blockhash not found");

        // Perform preemptively asserted queries
        uint256 nCalls = callSpecs.length;
        bytes32[] memory returnHashes = new bytes32[](nCalls);
        for (uint256 i = 0; i < nCalls; i++) {
            require(callSpecs[i].destination != address(publicationFeed), "Cannot call publication feed");
            (bool success, bytes memory returndata) = callSpecs[i].destination.call(callSpecs[i].callData);
            require(success, "Query failed");
            returnHashes[i] = keccak256(returndata);
        }

        bytes[] memory attributes = new bytes[](4);
        attributes[METADATA] = abi.encode(metadata);
        attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
        attributes[BLOB_REFERENCE] = abi.encode(blobRefRegistry.getRef(_buildBlobIndices(nBlobs)));
        attributes[L1_CALLS] = abi.encode(callSpecs, returnHashes);

        proposerFees.payPublicationFee(msg.sender, false);
        _lastPublicationId = publicationFeed.publish(attributes).id;

        // Publish each delayed inclusion as a separate publication
        IDelayedInclusionStore.Inclusion[] memory inclusions = processDueInclusions();
        uint256 nInclusions = inclusions.length;
        // Metadata is the same as the regular publication, so we just set `isDelayedInclusion` to true
        metadata.isDelayedInclusion = true;
        delete attributes[L1_CALLS];
        for (uint256 i; i < nInclusions; ++i) {
            attributes[METADATA] = abi.encode(metadata);
            attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
            attributes[BLOB_REFERENCE] = abi.encode(inclusions[i]);

            proposerFees.payPublicationFee(msg.sender, true);
            _lastPublicationId = publicationFeed.publish(attributes).id;
        }

        lastPublicationId = uint64(_lastPublicationId);
    }

    function _buildBlobIndices(uint256 nBlobs) private pure returns (uint256[] memory blobIndices) {
        blobIndices = new uint256[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobIndices[i] = i;
        }
    }
}
