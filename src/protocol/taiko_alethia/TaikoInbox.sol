// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "../IDataFeed.sol";

import {IDelayedInclusionStore} from "./IDelayedInclusionStore.sol";
import {ILookahead} from "./ILookahead.sol";
import {ITaikoData} from "./ITaikoData.sol";

contract TaikoInbox {
    IDataFeed public immutable datafeed;
    ILookahead public immutable lookahead;
    IDelayedInclusionStore public immutable delayedInclusionStore;

    uint256 public immutable maxAnchorBlockIdOffset;

    uint256 public prevPublicationId;

    constructor(
        address _datafeed,
        address _lookahead,
        address _delayedInclusionStore,
        uint256 _maxAnchorBlockIdOffset
    ) {
        datafeed = IDataFeed(_datafeed);
        lookahead = ILookahead(_lookahead);
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
        attributes[0] = abi.encode(anchorBlockId, anchorBlockhash);

        // Build the attribute to link back to the previous publication Id;
        attributes[1] = abi.encode(_prevPublicationId);

        // Build the attribute for this proposal's data availability
        bytes32[] memory blobHashes = new bytes32[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobHashes[i] = blobhash(i);
            require(blobHashes[i] != 0, "data unavailable");
        }
        attributes[2] = abi.encode(blobHashes);
        _prevPublicationId = datafeed.publish(attributes).id;

        // Publish each inclusion as a publication
        ITaikoData.DataSource[] memory dataSources =
            delayedInclusionStore.processDelayedInclusionByDeadline(block.timestamp);

        uint256 nDataSources = dataSources.length;
        for (uint256 i; i < nDataSources; ++i) {
            attributes[1] = abi.encode(_prevPublicationId);
            attributes[2] = abi.encode(dataSources[i].blobHashes);
            _prevPublicationId = datafeed.publish(attributes).id;
        }

        prevPublicationId = _prevPublicationId;
    }
}
