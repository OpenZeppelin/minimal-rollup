// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPublicationHook} from "../IPublicationHook.sol";

import {IDataFeed} from "./IDataFeed.sol";
import {ILookahead} from "./ILookahead.sol";

contract TaikoHookProvider is IPublicationHook {
    uint256 public immutable maxAnchorBlockIdOffset;
    address public immutable lookahead;

    constructor(uint256 _maxAnchorBlockIdOffset, address _lookahead) {
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
        lookahead = _lookahead;
    }

    /// @inheritdoc IPublicationHook
    function beforePublish(address publisher, bytes memory input) external payable override returns (bytes memory) {
        require(msg.value == 0, "ETH not required");

        if (lookahead != address(0)) {
            require(ILookahead(lookahead).isCurrentPreconfer(publisher), "not current preconfer");
        }

        uint64 anchorBlockId = abi.decode(input, (uint64));
        require(maxAnchorBlockIdOffset + anchorBlockId >= block.number, "anchorBlockId is too old");

        bytes32 anchorBlockhash = blockhash(anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");
        return abi.encode(anchorBlockhash);
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
