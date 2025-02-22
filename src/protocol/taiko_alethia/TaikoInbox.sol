// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

import {IDataFeed} from "../IDataFeed.sol";

import {IDelayedInclusionStore} from "./IDelayedInclusionStore.sol";
import {ILookahead} from "./ILookahead.sol";

contract TaikoInbox {
    IDataFeed public immutable datafeed;
    ILookahead public immutable lookahead;
    IBlobRefRegistry public immutable blobRefRegistry;
    IDelayedInclusionStore public immutable delayedInclusionStore;

    uint256 public immutable maxAnchorBlockIdOffset;

    uint256 public prevPublicationId;

    constructor(
        address _datafeed,
        address _lookahead,
        address _blobRefRegistry,
        address _delayedInclusionStore,
        uint256 _maxAnchorBlockIdOffset
    ) {
        datafeed = IDataFeed(_datafeed);
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
        uint256 _prevPublicationId = prevPublicationId;

        // Build the attribute for the anchor transaction inputs
        require(anchorBlockId >= block.number - maxAnchorBlockIdOffset, "anchorBlockId is too old");
        bytes32 anchorBlockhash = blockhash(anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");
        attributes[0] = abi.encode(datafeed.getNextPublicationId(), anchorBlockId, anchorBlockhash);

        // Build the attribute to link back to the previous publication Id;
        attributes[1] = abi.encode(_prevPublicationId);

        attributes[2] = abi.encode(blobRefRegistry.getRef(_buildBlobIndices(nBlobs)));
        _prevPublicationId = datafeed.publish(attributes).id;

        // Publish each delayed inclusion as a separate publication
        IBlobRefRegistry.BlobRef[] memory blobRefs =
            delayedInclusionStore.processDelayedInclusionByDeadline(block.timestamp);

        uint256 nBlobRefs = blobRefs.length;
        for (uint256 i; i < nBlobRefs; ++i) {
            attributes[1] = abi.encode(_prevPublicationId);
            attributes[2] = abi.encode(blobRefs[i]);
            _prevPublicationId = datafeed.publish(attributes).id;
        }

        prevPublicationId = _prevPublicationId;
    }

    function _buildBlobIndices(uint256 nBlobs) private pure returns (uint256[] memory blobIndices) {
        blobIndices = new uint256[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobIndices[i] = i;
        }
    }
}
