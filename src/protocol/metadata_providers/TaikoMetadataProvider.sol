// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IMetadataProvider} from "../IMetadataProvider.sol";

contract TaikoMetadataProvider is IMetadataProvider {
    uint256 public immutable maxAnchorBlockIdOffset;

    constructor(uint256 _maxAnchorBlockIdOffset) {
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
    }

    /// @inheritdoc IMetadataProvider
    function getMetadata(address, /*publisher*/ bytes memory input) external payable override returns (bytes memory) {
        uint64 anchorBlockId = abi.decode(input, (uint64));
        require(maxAnchorBlockIdOffset + anchorBlockId >= block.number, "anchorBlockId is too old");

        bytes32 anchorBlockhash = blockhash(anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");
        return abi.encode(anchorBlockhash);
    }
}
