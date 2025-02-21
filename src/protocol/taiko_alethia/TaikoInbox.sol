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

        require(anchorBlockId >= block.number - maxAnchorBlockIdOffset, "anchorBlockId is too old");
        bytes32 anchorBlockhash = blockhash(anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");

        bytes32[] memory blobHashes = new bytes32[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobHashes[i] = blobhash(i);
            require(blobHashes[i] != 0, "data unavailable");
        }

        ITaikoData.DataSource[] memory dataSources = new ITaikoData.DataSource[](1);
        dataSources[0].blobHashes = blobHashes;

        bytes[] memory attributes = new bytes[](1);
        attributes[0] = abi.encode(ITaikoData.Proposal(anchorBlockhash, dataSources));
        datafeed.publish(attributes);

        dataSources = delayedInclusionStore.processDelayedInclusionByDeadline(block.timestamp);
        if (dataSources.length > 0) {
            attributes[0] = abi.encode(ITaikoData.Proposal(anchorBlockhash, dataSources));
            datafeed.publish(attributes);
        }
    }
}
