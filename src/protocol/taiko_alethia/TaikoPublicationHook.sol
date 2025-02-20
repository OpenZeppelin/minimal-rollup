// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "../IDataFeed.sol";
import {IPublicationHook} from "../IPublicationHook.sol";

import {IDelayedInclusionStore} from "./IDelayedInclusionStore.sol";
import {ILookahead} from "./ILookahead.sol";

contract TaikoPublicationHook is IPublicationHook {
    struct PrehookInput {
        uint64 anchorBlockId;
        uint8 numBlobs;
    }

    struct TaikoProposal {
        bytes32 anchorBlockhash;
        // If blobHashes are not empty, all blobs in a group will be concatenated into a single blob and will be decoded
        // by node/client as a TaikoProposalType1 object (defined in node/client);
        bytes32[][] blobGroups;
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

        bytes32[][] memory blobGroups = new bytes32[][](1);
        blobGroups[0] = new bytes32[](_input.numBlobs);
        for (uint8 i; i < _input.numBlobs; i++) {
            blobGroups[0][i] = blockhash(_input.anchorBlockId + i);
            require(blobGroups[0][i] != 0, "blob not found");
        }

        return abi.encode(TaikoProposal(anchorBlockhash, blobGroups));
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

        bytes32[][] memory blobGroups = delayedInclusionStore.processDelayedInclusionByDeadline(block.timestamp);

        IDataFeed.HookQuery[] memory emptyHookQuery;
        IDataFeed(dataFeed).publish(0, abi.encode(blobGroups), emptyHookQuery, emptyHookQuery);
    }
}
