// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

import {IPublicationFeed} from "../IPublicationFeed.sol";

import {ISignalService} from "../ISignalService.sol";

import {IDelayedInclusionStore} from "./IDelayedInclusionStore.sol";
import {ILookahead} from "./ILookahead.sol";

contract TaikoInbox {
    struct Metadata {
        uint256 anchorBlockId;
        bytes32 anchorBlockHash;
        bool isDelayedInclusion;
        bytes32[] signalSlots;
    }

    IPublicationFeed public immutable publicationFeed;
    ILookahead public immutable lookahead;
    IBlobRefRegistry public immutable blobRefRegistry;
    IDelayedInclusionStore public immutable delayedInclusionStore;
    ISignalService public immutable signalService;

    uint256 public immutable maxAnchorBlockIdOffset;

    uint64 public lastPublicationId;

    // attributes associated with the publication
    uint256 private constant METADATA = 0;
    uint256 private constant LAST_PUBLICATION = 1;
    uint256 private constant BLOB_REFERENCE = 2;

    constructor(
        address _publicationFeed,
        address _lookahead,
        address _blobRefRegistry,
        address _delayedInclusionStore,
        address _signalService,
        uint256 _maxAnchorBlockIdOffset
    ) {
        publicationFeed = IPublicationFeed(_publicationFeed);
        lookahead = ILookahead(_lookahead);
        blobRefRegistry = IBlobRefRegistry(_blobRefRegistry);
        delayedInclusionStore = IDelayedInclusionStore(_delayedInclusionStore);
        signalService = ISignalService(_signalService);
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
    }

    function publish(uint256 nBlobs, uint64 anchorBlockId, bytes32[] calldata signalSlots) external {
        if (address(lookahead) != address(0)) {
            require(lookahead.isCurrentPreconfer(msg.sender), "not current preconfer");
        }

        uint256 _lastPublicationId = lastPublicationId;

        // Build the attribute for the anchor transaction inputs
        require(anchorBlockId >= block.number - maxAnchorBlockIdOffset, "anchorBlockId too old");

        _verifySignalSlots(signalSlots);

        Metadata memory metadata = Metadata({
            anchorBlockId: anchorBlockId,
            anchorBlockHash: blockhash(anchorBlockId),
            isDelayedInclusion: false,
            signalSlots: signalSlots
        });
        require(metadata.anchorBlockHash != 0, "blockhash not found");

        bytes[] memory attributes = new bytes[](3);
        attributes[METADATA] = abi.encode(metadata);
        attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
        attributes[BLOB_REFERENCE] = abi.encode(blobRefRegistry.getRef(_buildBlobIndices(nBlobs)));

        _lastPublicationId = publicationFeed.publish(attributes).id;

        // Publish each delayed inclusion as a separate publication
        IDelayedInclusionStore.Inclusion[] memory inclusions = delayedInclusionStore.processDueInclusions();
        uint256 nInclusions = inclusions.length;
        // Metadata is the same as the regular publication, so we just set `isDelayedInclusion` to true
        metadata.isDelayedInclusion = true;
        for (uint256 i; i < nInclusions; ++i) {
            attributes[METADATA] = abi.encode(metadata);
            attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
            attributes[BLOB_REFERENCE] = abi.encode(inclusions[i]);

            _lastPublicationId = publicationFeed.publish(attributes).id;
        }

        lastPublicationId = uint64(_lastPublicationId);
    }

    function _buildBlobIndices(uint256 nBlobs) private pure returns (uint256[] memory blobIndices) {
        blobIndices = new uint256[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobIndices[i] = i;
        }
    }

    function _verifySignalSlots(bytes32[] calldata signalSlots) private view {
        for (uint256 i; i < signalSlots.length; ++i) {
            require(signalService.isSignalSent(signalSlots[i]), "signal not sent");
        }
    }
}
