// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IMetadataProvider} from "../IMetadataProvider.sol";
import {ILookahead} from "./ILookahead.sol";

contract TaikoMetadataProvider is IMetadataProvider {
    uint256 public immutable maxAnchorBlockIdOffset;
    address public immutable lookahead;

    constructor(uint256 _maxAnchorBlockIdOffset, address _lookahead) {
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
        lookahead = _lookahead;
    }

    /// @inheritdoc IMetadataProvider
    function getMetadata(address publisher, bytes memory input) external payable override returns (bytes memory) {
        require(
            lookahead == address(0) || ILookahead(lookahead).isCurrentPreconfer(publisher),
            "publisher is not a current preconfer"
        );

        uint64 anchorBlockId = abi.decode(input, (uint64));
        require(maxAnchorBlockIdOffset + anchorBlockId >= block.number, "anchorBlockId is too old");

        bytes32 anchorBlockhash = blockhash(anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");
        return abi.encode(anchorBlockhash);
    }
}
