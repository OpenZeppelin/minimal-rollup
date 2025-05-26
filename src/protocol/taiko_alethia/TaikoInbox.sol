// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

import {IDelayedInclusionStore} from "../IDelayedInclusionStore.sol";
import {IPublicationFeed} from "../IPublicationFeed.sol";
import {DelayedInclusionStore} from "./DelayedInclusionStore.sol";

import {IInbox} from "../IInbox.sol";
import {ILookahead} from "../ILookahead.sol";
import {IProposerFees} from "../IProposerFees.sol";

contract TaikoInbox is IInbox, IPublicationFeed, DelayedInclusionStore {
    struct Metadata {
        uint256 anchorBlockId;
        bytes32 anchorBlockHash;
        bool isDelayedInclusion;
    }

    ILookahead public immutable lookahead;
    IProposerFees public immutable proposerFees;
    uint256 public immutable maxAnchorBlockIdOffset;

    // attributes associated with the publication
    uint256 private constant METADATA = 0;
    uint256 private constant LAST_PUBLICATION = 1;
    uint256 private constant BLOB_REFERENCE = 2;

    bytes32[] private _publicationHashes;

    constructor(
        address _lookahead,
        address _blobRefRegistry,
        uint256 _maxAnchorBlockIdOffset,
        address _proposerFees,
        uint256 _inclusionDelay
    ) DelayedInclusionStore(_inclusionDelay, _blobRefRegistry) {
        require(_proposerFees != address(0), "Invalid proposer fees address");

        lookahead = ILookahead(_lookahead);
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
        proposerFees = IProposerFees(_proposerFees);

        // guarantee there is always a previous hash
        _publicationHashes.push(0);
    }

    /// @inheritdoc IInbox
    function publish(uint256 nBlobs, uint64 anchorBlockId) external payable {
        if (address(lookahead) != address(0)) {
            require(lookahead.isCurrentPreconfer(msg.sender), "not current preconfer");
        }

        uint256 _lastPublicationId = _publicationHashes.length - 1;

        // Build the attribute for the anchor transaction inputs
        require(anchorBlockId >= block.number - maxAnchorBlockIdOffset, "anchorBlockId too old");

        Metadata memory metadata = Metadata({
            anchorBlockId: anchorBlockId,
            anchorBlockHash: blockhash(anchorBlockId),
            isDelayedInclusion: false
        });
        require(metadata.anchorBlockHash != 0, "blockhash not found");

        bytes[] memory attributes = new bytes[](3);
        attributes[METADATA] = abi.encode(metadata);
        attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
        attributes[BLOB_REFERENCE] = abi.encode(blobRefRegistry.getRef(_buildBlobIndices(nBlobs)));

        proposerFees.payPublicationFee(msg.sender, false);
        _lastPublicationId = _publish(attributes).id;

        // Publish each delayed inclusion as a separate publication
        IDelayedInclusionStore.Inclusion[] memory inclusions = processDueInclusions();
        uint256 nInclusions = inclusions.length;
        // Metadata is the same as the regular publication, so we just set `isDelayedInclusion` to true
        metadata.isDelayedInclusion = true;
        for (uint256 i; i < nInclusions; ++i) {
            attributes[METADATA] = abi.encode(metadata);
            attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
            attributes[BLOB_REFERENCE] = abi.encode(inclusions[i]);

            proposerFees.payPublicationFee(msg.sender, true);
            _lastPublicationId = _publish(attributes).id;
        }
    }

    /// @dev Internal implementation of publication logic
    /// @param attributes The data to publish
    /// @return header The publication header
    function _publish(bytes[] memory attributes) internal returns (PublicationHeader memory header) {
        uint256 nAttributes = attributes.length;
        bytes32[] memory attributeHashes = new bytes32[](nAttributes);
        for (uint256 i; i < nAttributes; ++i) {
            attributeHashes[i] = keccak256(attributes[i]);
        }

        uint256 id = _publicationHashes.length;
        header = PublicationHeader({
            id: id,
            prevHash: _publicationHashes[id - 1],
            publisher: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number,
            attributesHash: keccak256(abi.encode(attributeHashes))
        });

        bytes32 pubHash = keccak256(abi.encode(header));
        _publicationHashes.push(pubHash);

        emit Published(pubHash, header, attributes);
    }

    /// @inheritdoc IPublicationFeed
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return _publicationHashes[idx];
    }

    /// @inheritdoc IPublicationFeed
    function getNextPublicationId() external view returns (uint256) {
        return _publicationHashes.length;
    }

    /// @inheritdoc IPublicationFeed
    function validateHeader(PublicationHeader calldata header) external view returns (bool) {
        return keccak256(abi.encode(header)) == _publicationHashes[header.id];
    }

    /// @dev Builds blob indices array for the given number of blobs
    /// @param nBlobs Number of blobs to create indices for
    /// @return blobIndices Array of blob indices
    function _buildBlobIndices(uint256 nBlobs) private pure returns (uint256[] memory blobIndices) {
        blobIndices = new uint256[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobIndices[i] = i;
        }
    }
}
