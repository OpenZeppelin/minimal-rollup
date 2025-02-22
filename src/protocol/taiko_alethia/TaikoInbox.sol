// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

import {IDataFeed} from "../IDataFeed.sol";

import {IDelayedInclusionStore} from "./IDelayedInclusionStore.sol";
import {ILookahead} from "./ILookahead.sol";

contract TaikoInbox {
    IDataFeed public immutable dataFeed;
    ILookahead public immutable lookahead;
    IBlobRefRegistry public immutable blobRefRegistry;
    IDelayedInclusionStore public immutable delayedInclusionStore;

    uint256 public immutable maxAnchorBlockIdOffset;

    uint256 public lastPublicationId;

    // attributes associated with the publication
    uint256 private constant ANCHOR_TX = 0;
    uint256 private constant PREV_PUBLICATION = 1;
    uint256 private constant BLOB_REFERENCE = 2;

    constructor(
        address _dataFeed,
        address _lookahead,
        address _blobRefRegistry,
        address _delayedInclusionStore,
        uint256 _maxAnchorBlockIdOffset
    ) {
        dataFeed = IDataFeed(_dataFeed);
        lookahead = ILookahead(_lookahead);
        blobRefRegistry = IBlobRefRegistry(_blobRefRegistry);
        delayedInclusionStore = IDelayedInclusionStore(_delayedInclusionStore);
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
    }

    function publish(uint256 nBlobs, uint64 anchorBlockId) external {
        if (address(lookahead) != address(0)) {
            require(lookahead.isCurrentPreconfer(msg.sender), "not current preconfer");
        }

        bytes[] memory attributes = new bytes[](3);
        uint256 _lastPublicationId = lastPublicationId;

        // Build the attribute for the anchor transaction inputs
        require(anchorBlockId >= block.number - maxAnchorBlockIdOffset, "anchorBlockId is too old");
        bytes32 anchorBlockhash = blockhash(anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");
        attributes[ANCHOR_TX] = abi.encode(anchorBlockId, anchorBlockhash);

        // Build the attribute to link back to the previous publication Id;
        attributes[PREV_PUBLICATION] = abi.encode(_lastPublicationId);

        attributes[BLOB_REFERENCE] = abi.encode(blobRefRegistry.getRef(_buildBlobIndices(nBlobs)));
        _lastPublicationId = dataFeed.publish(attributes).id;

        // Publish each delayed inclusion as a separate publication
        IBlobRefRegistry.BlobRef[] memory blobRefs =
            delayedInclusionStore.processDelayedInclusionByDeadline(block.timestamp);

        uint256 nBlobRefs = blobRefs.length;
        for (uint256 i; i < nBlobRefs; ++i) {
            attributes[PREV_PUBLICATION] = abi.encode(_lastPublicationId);
            attributes[BLOB_REFERENCE] = abi.encode(blobRefs[i]);
            _lastPublicationId = dataFeed.publish(attributes).id;
        }

        lastPublicationId = _lastPublicationId;
    }

    function _buildBlobIndices(uint256 nBlobs) private pure returns (uint256[] memory blobIndices) {
        blobIndices = new uint256[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobIndices[i] = i;
        }
    }
}
