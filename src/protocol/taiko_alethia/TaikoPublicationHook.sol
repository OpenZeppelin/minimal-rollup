// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPublicationHook} from "../IPublicationHook.sol";

import {IDataFeed} from "../IDataFeed.sol";
import {ILookahead} from "./ILookahead.sol";

contract TaikoPublicationHook is IPublicationHook {
    struct PrehookInput {
        uint64 anchorBlockId;
        uint8 numBlobs;
    }

    struct PosthookOutput {
        bytes32 anchorBlockhash;
        bytes32[] blobHashes;
    }

    address public immutable dataFeed;
    address public immutable lookahead;
    uint256 public immutable maxAnchorBlockOffset;

    constructor(address _dataFeed, address _lookahead, uint256 _maxAnchorBlockOffset) {
        dataFeed = _dataFeed;
        lookahead = _lookahead;
        maxAnchorBlockOffset = _maxAnchorBlockOffset;
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
        require(_input.numBlobs > 0, "numBlobs must be greater than 0");

        bytes32 anchorBlockhash = blockhash(_input.anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");

        bytes32[] memory blobHashes = new bytes32[](_input.numBlobs);
        for (uint8 i; i < _input.numBlobs; i++) {
            blobHashes[i] = blockhash(_input.anchorBlockId + i);
            require(blobHashes[i] != 0, "blob not found");
        }

        return abi.encode(PosthookOutput(anchorBlockhash, blobHashes));
    }

    /// @inheritdoc IPublicationHook
    function afterPublish(address publisher, IDataFeed.Publication memory publication, bytes memory input)
        external
        payable
        override
        onlyFromDataFeedByPreconfer(publisher)
    {
        // TODO: Implement

        // If we call dataFeed.publish(), the msg.sender is this contract, which is wrong.
    }
}
