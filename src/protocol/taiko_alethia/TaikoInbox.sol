// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "../IDataFeed.sol";
import {ILookahead} from "./ILookahead.sol";

contract TaikoInbox {
    IDataFeed public immutable datafeed;
    ILookahead public immutable lookahead;
    uint256 public immutable maxAnchorBlockIdOffset;

    constructor(address _datafeed, address _lookahead, uint256 _maxAnchorBlockIdOffset) {
        datafeed = IDataFeed(_datafeed);
        lookahead = ILookahead(_lookahead);
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
    }

    function publish(uint256 nBlobs, bytes calldata data, uint64 anchorBlockId) external {
        if (address(lookahead) != address(0)) {
            require(lookahead.isCurrentPreconfer(msg.sender), "not current preconfer");
        }

        require(anchorBlockId >= block.number - maxAnchorBlockIdOffset, "anchorBlockId is too old");
        bytes32 anchorBlockhash = blockhash(anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");

        bytes32[] memory blobHashes = new bytes32[](nBlobs);
        for(uint i; i < nBlobs; ++i) {
            blobHashes[i] = blobhash(i);
            require(blobHashes[i] != 0, "data unavailable");
        }

        bytes memory publicationData =  abi.encode(keccak256(abi.encode(anchorBlockhash, data, blobHashes)));
        datafeed.publish(publicationData);
    }
}
