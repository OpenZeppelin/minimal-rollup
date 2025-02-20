// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "../IDataFeed.sol";
import {IPublicationHook} from "../IPublicationHook.sol";

import {IDelayedInclusionStore} from "./IDelayedInclusionStore.sol";
import {ILookahead} from "./ILookahead.sol";
import {ITaikoData} from "./ITaikoData.sol";

contract TaikoPublicationHook is IPublicationHook {
    struct PrehookInput {
        uint64 anchorBlockId;
        uint8 numBlobs;
    }

    struct PosthookInput {
        bytes32[] inclusionHashes;
    }

    address public immutable dataFeed;
    address public immutable lookahead;
    uint256 public immutable maxAnchorBlockOffset;
    IDelayedInclusionStore public immutable delayedInclusionStore;

    constructor(address _dataFeed, address _lookahead, uint256 _maxAnchorBlockOffset, address _delayedInclusionStore) {
        dataFeed = _dataFeed;
        lookahead = _lookahead;
        maxAnchorBlockOffset = _maxAnchorBlockOffset;
        delayedInclusionStore = IDelayedInclusionStore(_delayedInclusionStore);
    }

    modifier onlyFromDataFeedByPreconfer(address publisher) {
        require(msg.sender == dataFeed, "not datafeed");
        if (lookahead != address(0)) {
            require(ILookahead(lookahead).isCurrentPreconfer(publisher), "not current preconfer");
        }
        _;
    }

    /// @inheritdoc IPublicationHook
    function beforePublish(address publisher, bytes memory input)
        external
        payable
        override
        onlyFromDataFeedByPreconfer(publisher)
        returns (bytes memory)
    {
        require(msg.value == 0, "ETH not required");

        PrehookInput memory _input = abi.decode(input, (PrehookInput));
        require(maxAnchorBlockOffset + _input.anchorBlockId >= block.number, "anchorBlockId too old");
        require(_input.numBlobs > 0, "no blobs used");

        bytes32 anchorBlockhash = blockhash(_input.anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");

        bytes32[] memory blobs = new bytes32[](_input.numBlobs);
        for (uint8 i; i < _input.numBlobs; i++) {
            blobs[i] = blockhash(_input.anchorBlockId + i);
            require(blobs[i] != 0, "blob not found");
        }

        ITaikoData.DataSource[] memory dataSources = new ITaikoData.DataSource[](1);
        dataSources[0].blobs = blobs;

        return abi.encode(ITaikoData.Proposal(anchorBlockhash, dataSources));
    }

    /// @inheritdoc IPublicationHook
    function afterPublish(address publisher, IDataFeed.Publication memory, /* publication */ bytes memory input)
        external
        payable
        override
        onlyFromDataFeedByPreconfer(publisher)
    {
        require(input.length == 0, "input not supported");
        require(msg.value == 0, "ETH not required");

        ITaikoData.DataSource[] memory dataSources =
            delayedInclusionStore.processDelayedInclusionByDeadline(block.timestamp);

        if (dataSources.length > 0) {
            bytes memory data = abi.encode(ITaikoData.Proposal(0, dataSources));
            IDataFeed.HookQuery[] memory emptyHooks;
            IDataFeed(dataFeed).publish{value: 0}(0, data, emptyHooks, emptyHooks);
        }
    }
}
