// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";
import {IDelayedInclusionStore} from "../IDelayedInclusionStore.sol";
import {IPublicationFeed} from "../IPublicationFeed.sol";
import {DelayedInclusionStore} from "../taiko_alethia/DelayedInclusionStore.sol";
import {IProposerFees} from "../IProposerFees.sol";
import {IRegistry} from "urc/src/IRegistry.sol";


contract FabricInbox is DelayedInclusionStore {
    struct Metadata {
        uint256 anchorBlockId;
        bytes32 anchorBlockHash;
        bool isDelayedInclusion;
    }

    IPublicationFeed public immutable publicationFeed;
    IProposerFees public immutable proposerFees;
    IRegistry public immutable registry;
    uint256 public immutable maxAnchorBlockIdOffset;
    uint64 public lastPublicationId;
    mapping(uint256 blockNumber => uint256 timestamp) public timestamps;

    // URC-related parameters
    address public immutable slasher;
    uint256 public immutable requiredCollateralWei;

    // EIP-4788
    address private constant beaconRootsContract =
        0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;
    uint256 private immutable GENESIS_TIMESTAMP;

    // attributes associated with the publication
    uint256 private constant METADATA = 0;
    uint256 private constant LAST_PUBLICATION = 1;
    uint256 private constant BLOB_REFERENCE = 2;
    uint256 private constant BEACON_BLOCK_ROOT = 3;
    uint256 private constant VALIDATOR_PUBKEY = 4;

    constructor(
        address _publicationFeed,
        address _blobRefRegistry,
        address _registry,
        address _slasher,
        uint256 _maxAnchorBlockIdOffset,
        address _proposerFees,
        uint256 _inclusionDelay,
        uint256 _requiredCollateralWei,
        uint256 _genesisTimestamp
    ) DelayedInclusionStore(_inclusionDelay, _blobRefRegistry) {
        publicationFeed = IPublicationFeed(_publicationFeed);
        registry = IRegistry(_registry);
        slasher = _slasher;
        maxAnchorBlockIdOffset = _maxAnchorBlockIdOffset;
        proposerFees = IProposerFees(_proposerFees);
        requiredCollateralWei = _requiredCollateralWei;
        GENESIS_TIMESTAMP = _genesisTimestamp;
    }

    function publish(
        uint256 nBlobs,
        uint64 anchorBlockId,
        IRegistry.RegistrationProof calldata registrationProof
    ) external payable isAllowedProposer(registrationProof) {
        uint256 _lastPublicationId = lastPublicationId;

        // Build the attribute for the anchor transaction inputs
        require(
            anchorBlockId >= block.number - maxAnchorBlockIdOffset,
            "anchorBlockId too old"
        );

        Metadata memory metadata = Metadata({
            anchorBlockId: anchorBlockId,
            anchorBlockHash: blockhash(anchorBlockId),
            isDelayedInclusion: false
        });
        require(metadata.anchorBlockHash != 0, "blockhash not found");

        bytes[] memory attributes = new bytes[](5);
        attributes[METADATA] = abi.encode(metadata);
        attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
        attributes[BLOB_REFERENCE] = abi.encode(
            blobRefRegistry.getRef(_buildBlobIndices(nBlobs))
        );
        attributes[BEACON_BLOCK_ROOT] = abi.encode(
            getBeaconBlockRootFromTimestamp(timestamps[anchorBlockId])
        );
        attributes[VALIDATOR_PUBKEY] = abi.encode(
            registrationProof.registration.pubkey
        );

        (uint256 publicationFee, uint256 delayedPublicationFee) = proposerFees
            .getCurrentFees();
        proposerFees.payPublicationFee{value: publicationFee}(
            msg.sender,
            false
        );
        _lastPublicationId = publicationFeed.publish(attributes).id;

        // zero out the unused attributes for delayed inclusions
        attributes[VALIDATOR_PUBKEY] = bytes("");
        attributes[BEACON_BLOCK_ROOT] = bytes("");

        // Publish each delayed inclusion as a separate publication
        IDelayedInclusionStore.Inclusion[]
            memory inclusions = processDueInclusions();
        uint256 nInclusions = inclusions.length;
        // Metadata is the same as the regular publication, so we just set `isDelayedInclusion` to true
        metadata.isDelayedInclusion = true;
        for (uint256 i; i < nInclusions; ++i) {
            attributes[METADATA] = abi.encode(metadata);
            attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
            attributes[BLOB_REFERENCE] = abi.encode(inclusions[i]);

            proposerFees.payPublicationFee{value: delayedPublicationFee}(
                msg.sender,
                true
            );
            _lastPublicationId = publicationFeed.publish(attributes).id;
        }

        lastPublicationId = uint64(_lastPublicationId);

        // Save the current timestamp to be retrieved in future calls to publish()
        timestamps[block.number] = block.timestamp;
    }

    function _buildBlobIndices(
        uint256 nBlobs
    ) private pure returns (uint256[] memory blobIndices) {
        blobIndices = new uint256[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobIndices[i] = i;
        }
    }

    modifier isAllowedProposer(
        IRegistry.RegistrationProof calldata registrationProof
    ) {
        // Get the URC's config
        IRegistry.Config memory config = registry.getConfig();

        // Get the data of the operator from the URC
        // This will revert if the proof is invalid
        IRegistry.OperatorData memory operator = registry
            .getVerifiedOperatorData(registrationProof);

        // Perform sanity checks on the operator's data
        require(
            operator.collateralWei >= requiredCollateralWei,
            "Insufficient collateral"
        );

        require(operator.slashedAt == 0, "Operator has been slashed");

        // Verify operator has not unregistered
        if (operator.unregisteredAt != type(uint48).max) {
            require(
                block.number <
                    operator.unregisteredAt + config.unregistrationDelay,
                "Operator unregistered"
            );
        }

        // Get information about the operator's commitment to the rollup's specified slasher
        IRegistry.SlasherCommitment memory slasherCommitment = registry
            .getSlasherCommitment(registrationProof.registrationRoot, slasher);

        // Perform sanity checks on the slasher commitment
        require(
            slasherCommitment.optedOutAt < slasherCommitment.optedInAt,
            "Not opted into slasher"
        );

        require(slasherCommitment.slashed == false, "Operator has been slashed");

        require(
            slasherCommitment.committer == msg.sender,
            "Wrong blob submitter address"
        );

        require(
            block.number >
                slasherCommitment.optedInAt + config.optInDelay,
            "Too early to make commitments"
        );

        // todo potentially check collateral history

        // todo other checks?

        _;
    }

    // source: https://github.com/nerolation/slashing-proofoor/blob/main/src/SlashingProofoor.sol
    function getBeaconBlockRootFromTimestamp(
        uint256 timestamp
    ) public returns (bytes32) {
        (bool ret, bytes memory data) = beaconRootsContract.call(
            bytes.concat(bytes32(timestamp))
        );
        require(ret);
        return bytes32(data);
    }

    function slotToTimestamp(uint256 slot) public view returns (uint256) {
        return slot * 12 + GENESIS_TIMESTAMP;
    }
}