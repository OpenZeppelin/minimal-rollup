// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

import {IPublicationFeed} from "../IPublicationFeed.sol";

import {IDelayedInclusionStore} from "../IDelayedInclusionStore.sol";
import {IInbox} from "../IInbox.sol";
import {ILookahead} from "../ILookahead.sol";

import {L1Query} from "./preemptive_assertions/L1QueriesPublicationTime.sol";

contract TaikoInbox is IInbox {
    struct Metadata {
        uint256 anchorBlockId;
        bytes32 anchorBlockHash;
        bool isDelayedInclusion;
    }

    IPublicationFeed public immutable publicationFeed;
    ILookahead public immutable lookahead;
    IBlobRefRegistry public immutable blobRefRegistry;
    IDelayedInclusionStore public immutable delayedInclusionStore;

    uint256 public immutable maxAnchorBlockIdOffset;

    uint64 public lastPublicationId;

    // attributes associated with the publication
    uint256 private constant METADATA = 0;
    uint256 private constant LAST_PUBLICATION = 1;
    uint256 private constant BLOB_REFERENCE = 2;
    uint256 private constant L1_QUERIES = 3;

    constructor(
        address _publicationFeed,
        address _lookahead,
        address _blobRefRegistry,
        address _delayedInclusionStore,
        uint256 _maxAnchorBlockIdOffset
    ) {
        publicationFeed = IPublicationFeed(_publicationFeed);
        lookahead = ILookahead(_lookahead);
        blobRefRegistry = IBlobRefRegistry(_blobRefRegistry);
        delayedInclusionStore = IDelayedInclusionStore(_delayedInclusionStore);
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
    }

    function publish(uint256 nBlobs, uint64 anchorBlockId, L1Query[] calldata queries) external {
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
        uint256 nQueries = queries.length;
        uint256[] memory results = new uint256[](nQueries);
        for (uint256 i = 0; i < nQueries; i++) {
            require(queries[i].destination != address(publicationFeed), "Cannot query publication feed");
            (bool success, bytes memory returndata) = queries[i].destination.call(queries[i].callData);
            require(success, "Query failed");
            results[i] = abi.decode(returndata, (uint256));
        }

        bytes[] memory attributes = new bytes[](4);
        attributes[METADATA] = abi.encode(metadata);
        attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
        attributes[BLOB_REFERENCE] = abi.encode(blobRefRegistry.getRef(_buildBlobIndices(nBlobs)));
        attributes[L1_QUERIES] = abi.encode(queries, results);

        _lastPublicationId = publicationFeed.publish(attributes).id;

        // Publish each delayed inclusion as a separate publication
        IDelayedInclusionStore.Inclusion[] memory inclusions = delayedInclusionStore.processDueInclusions();
        uint256 nInclusions = inclusions.length;
        // Metadata is the same as the regular publication, so we just set `isDelayedInclusion` to true
        metadata.isDelayedInclusion = true;
        delete attributes[L1_QUERIES];
        for (uint256 i; i < nInclusions; ++i) {
            attributes[METADATA] = abi.encode(metadata);
            attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
            attributes[BLOB_REFERENCE] = abi.encode(inclusions[i]);

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
