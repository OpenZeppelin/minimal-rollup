// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

import {IDataFeed} from "../IDataFeed.sol";

import {IDelayedInclusionStore} from "./IDelayedInclusionStore.sol";
import {ILookahead} from "./ILookahead.sol";
import {ITaikoData} from "./ITaikoData.sol";

contract TaikoInbox {
    IDataFeed public immutable datafeed;
    ILookahead public immutable lookahead;
    IBlobRefRegistry public immutable blobRefRegister;
    IDelayedInclusionStore public immutable delayedInclusionStore;

    uint256 public immutable maxAnchorBlockIdOffset;

    uint256 public prevPublicationId;

    constructor(
        address _datafeed,
        address _lookahead,
        address _blobRefRegister,
        address _delayedInclusionStore,
        uint256 _maxAnchorBlockIdOffset
    ) {
        datafeed = IDataFeed(_datafeed);
        lookahead = ILookahead(_lookahead);
        blobRefRegister = IBlobRefRegistry(_blobRefRegister);
        delayedInclusionStore = IDelayedInclusionStore(_delayedInclusionStore);
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
    }

    function publish(uint256 nBlobs, uint64 anchorBlockId) external {
        if (address(lookahead) != address(0)) {
            require(lookahead.isCurrentPreconfer(msg.sender), "not current preconfer");
        }

        bytes[] memory attributes = new bytes[](3);
        uint256 _prevPublicationId = prevPublicationId;

        // Build the attribute for the anchor transaction inputs
        require(anchorBlockId >= block.number - maxAnchorBlockIdOffset, "anchorBlockId is too old");
        bytes32 anchorBlockhash = blockhash(anchorBlockId);
        require(anchorBlockhash != 0, "blockhash not found");
        attributes[0] = abi.encode(anchorBlockId, anchorBlockhash);

        // Build the attribute to link back to the previous publication Id;
        attributes[1] = abi.encode(_prevPublicationId);

        ITaikoData.DataSource memory dataSource;
        dataSource.blobRef = blobRefRegister.getRef(_getBlobIndices(nBlobs));

        attributes[2] = abi.encode(dataSource);
        _prevPublicationId = datafeed.publish(attributes).id;

        // Publish each inclusion as a publication
        ITaikoData.DataSource[] memory dataSources =
            delayedInclusionStore.processDelayedInclusionByDeadline(block.timestamp);

        uint256 nDataSources = dataSources.length;
        for (uint256 i; i < nDataSources; ++i) {
            attributes[1] = abi.encode(_prevPublicationId);
            attributes[2] = abi.encode(dataSources[i]);
            _prevPublicationId = datafeed.publish(attributes).id;
        }

        prevPublicationId = _prevPublicationId;
    }

    function _getBlobIndices(uint256 nBlobs) private pure returns (uint256[] memory blobIndices) {
        blobIndices = new uint256[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobIndices[i] = i;
        }
    }
}
