// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "../IDataFeed.sol";
import {IMetadataProvider} from "../IMetadataProvider.sol";
import {ILookahead} from "./ILookahead.sol";

contract TaikoMetadataProvider is IMetadataProvider {
    uint256 public immutable maxAnchorBlockIdOffset;
    address public immutable lookahead;
    IDataFeed public immutable dataFeed;

    /// @dev This is the last direct publication hash that the rollup has "seen" and will force
    /// the sequencer to include as part of the next publication.
    bytes32 private lastDirectPublicationHash;

    constructor(uint256 _maxAnchorBlockIdOffset, address _lookahead, address _dataFeed) {
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
        lookahead = _lookahead;
        dataFeed = IDataFeed(_dataFeed);
    }

    /// @inheritdoc IMetadataProvider
    function getMetadata(address publisher, bytes memory input) external payable override returns (bytes memory) {
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

    /// @inheritdoc IMetadataProvider
    function setLastDirectPublicationHash(IDataFeed.DirectPublication calldata publication, uint256 idx) external {
        bytes32 dataFeedHash = dataFeed.getDirectPublicationHash(idx);
        bytes32 publicationHash = keccak256(abi.encode(publication));

        require(dataFeedHash == publicationHash, "dataFeedHash does not match publicationHash");

        lastDirectPublicationHash = publicationHash;
    }

    /// @inheritdoc IMetadataProvider
    function getDirectPublicationHash() external view returns (bytes32) {
        return lastDirectPublicationHash;
    }
}
