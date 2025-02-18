// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TaikoMetadataProvider {
    /// @notice Returns the block hash corresponding to the provided anchorBlockId
    /// @param anchorBlockId The block ID whose hash is used for L1->L2 synchronization
    /// @return anchorBlockhash The block hash of the anchor block
    function getMetadata(uint256 anchorBlockId) external view returns (bytes32) {
        bytes32 anchorBlockhash = blockhash(anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");
        return anchorBlockhash;
    }
}
