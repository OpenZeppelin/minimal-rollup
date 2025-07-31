// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

import {IDelayedInclusionStore} from "../IDelayedInclusionStore.sol";
import {DelayedInclusionStore} from "./DelayedInclusionStore.sol";

import {IInbox} from "../IInbox.sol";
import {ILookahead} from "../ILookahead.sol";
import {IProposerFees} from "../IProposerFees.sol";

contract TaikoInbox is IInbox, DelayedInclusionStore {
    /// @dev Caller is not the current preconfer
    error NotCurrentPreconfer();
    /// @dev Anchor block ID is too old
    error AnchorBlockTooOld();
    /// @dev Blockhash is not available for the anchor block
    error BlockhashUnavailable();

    struct Metadata {
        uint256 anchorBlockId;
        bytes32 anchorBlockHash;
        bool isDelayedInclusion;
    }

    ILookahead public immutable lookahead;
    IProposerFees public proposerFees;
    uint256 public immutable maxAnchorBlockIdOffset;

    address private immutable deployer;

    /// @notice Thrown when no proposer fee address is set
    error ProposerFeesNotInitialized();

    /// @dev Modifier to check if proposerFees has been initialized
    modifier checkProposerFeesInitialized() {
        bytes4 errorSelector = ProposerFeesNotInitialized.selector;
        assembly {
            let fees := sload(proposerFees.slot)
            if iszero(fees) {
                mstore(0, errorSelector)
                revert(0x00, 0x04)
            }
        }
        _;
    }

    /// @dev Modifier to check if the caller is the deployer
    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer can call this function");
        _;
    }

    // attributes associated with the publication
    uint256 private constant METADATA = 0;
    uint256 private constant BLOB_REFERENCE = 1;
    uint256 private constant NUM_ATTRIBUTES = 2;

    bytes32[] private _publicationHashes;

    constructor(address _lookahead, address _blobRefRegistry, uint256 _maxAnchorBlockIdOffset, uint256 _inclusionDelay)
        DelayedInclusionStore(_inclusionDelay, _blobRefRegistry)
    {
        lookahead = ILookahead(_lookahead);
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
        deployer = msg.sender;

        // guarantee there is always a previous hash
        _publicationHashes.push(0);
    }

    /// @inheritdoc IInbox
    function initializeProposerFees(address _proposerFees) external onlyDeployer {
        require(address(proposerFees) == address(0), "ProposerFees already initialized");
        require(_proposerFees != address(0), "ProposerFees cannot be zero");
        proposerFees = IProposerFees(_proposerFees);
        emit ProposerFeesInitialized(_proposerFees);
    }

    /// @inheritdoc IInbox
    function publish(uint256 nBlobs, uint64 anchorBlockId) external checkProposerFeesInitialized {
        if (address(lookahead) != address(0)) {
            require(lookahead.isCurrentPreconfer(msg.sender), NotCurrentPreconfer());
        }

        // Build the attribute for the anchor transaction inputs
        require(anchorBlockId >= block.number - maxAnchorBlockIdOffset, AnchorBlockTooOld());

        Metadata memory metadata = Metadata({
            anchorBlockId: anchorBlockId,
            anchorBlockHash: blockhash(anchorBlockId),
            isDelayedInclusion: false
        });
        require(metadata.anchorBlockHash != 0, BlockhashUnavailable());

        bytes[] memory attributes = new bytes[](NUM_ATTRIBUTES);
        attributes[METADATA] = abi.encode(metadata);
        attributes[BLOB_REFERENCE] = abi.encode(blobRefRegistry.getRef(_buildBlobIndices(nBlobs)));

        _publish(attributes, false);

        // Publish each delayed inclusion as a separate publication
        IDelayedInclusionStore.Inclusion[] memory inclusions = processDueInclusions();
        uint256 nInclusions = inclusions.length;

        // Metadata is the same as the regular publication, so we just set `isDelayedInclusion` to true
        metadata.isDelayedInclusion = true;
        for (uint256 i; i < nInclusions; ++i) {
            attributes[METADATA] = abi.encode(metadata);
            attributes[BLOB_REFERENCE] = abi.encode(inclusions[i]);

            _publish(attributes, true);
        }
    }

    /// @dev Internal implementation of publication logic
    /// @param attributes The data to publish
    /// @param isDelayed Whether this is a delayed inclusion publication
    function _publish(bytes[] memory attributes, bool isDelayed) internal {
        proposerFees.payPublicationFee(msg.sender, isDelayed);

        uint256 nAttributes = attributes.length;
        bytes32[] memory attributeHashes = new bytes32[](nAttributes);
        for (uint256 i; i < nAttributes; ++i) {
            attributeHashes[i] = keccak256(attributes[i]);
        }

        uint256 id = _publicationHashes.length;
        PublicationHeader memory header = PublicationHeader({
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

    /// @inheritdoc IInbox
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return _publicationHashes[idx];
    }

    /// @inheritdoc IInbox
    function getNextPublicationId() external view returns (uint256) {
        return _publicationHashes.length;
    }

    /// @inheritdoc IInbox
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
