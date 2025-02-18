// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TaikoMetadataProvider {
    uint256 public immutable maxAnchorBlockIdOffset;

    constructor(uint256 _maxAnchorBlockIdOffset) {
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
    }

    /// @notice Returns the block hash corresponding to the provided anchorBlockId
    /// @param anchorBlockId The block ID whose hash is used for L1->L2 synchronization
    /// @return anchorBlockhash The block hash of the anchor block
    function getMetadata(uint64 anchorBlockId) external view returns (bytes32 anchorBlockhash) {
        require(maxAnchorBlockIdOffset + anchorBlockId >= block.number, "anchorBlockId is too old");

        anchorBlockhash = blockhash(anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");
    }
}
