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

    uint256 public immutable maxAnchorBlockOffset;
    address public immutable lookahead;

    constructor(uint256 _maxAnchorBlockOffset, address _lookahead) {
        maxAnchorBlockOffset = _maxAnchorBlockOffset;
        lookahead = _lookahead;
    }

    /// @inheritdoc IPublicationHook
    function beforePublish(address publisher, bytes memory input) external payable override returns (bytes memory) {
        require(msg.value == 0, "ETH not required");

        if (lookahead != address(0)) {
            require(ILookahead(lookahead).isCurrentPreconfer(publisher), "not current preconfer");
        }

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
    {
        // TODO: Implement
    }
}
