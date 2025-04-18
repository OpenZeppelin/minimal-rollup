// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";

import {IDelayedInclusionStore} from "../IDelayedInclusionStore.sol";
import {IProposerFees} from "../IProposerFees.sol";
import {IPublicationFeed} from "../IPublicationFeed.sol";
import {DelayedInclusionStore} from "../taiko_alethia/DelayedInclusionStore.sol";

import {EIP4788} from "./EIP-4788.sol";
import {IRegistry} from "urc/src/IRegistry.sol";
import {BLS} from "urc/src/lib/BLS.sol";

contract FabricInbox is DelayedInclusionStore {
    struct Metadata {
        uint256 anchorBlockId;
        bytes32 anchorBlockHash;
        bool isDelayedInclusion;
    }

    // Contracts
    IPublicationFeed public immutable publicationFeed;
    IProposerFees public immutable proposerFees;
    IRegistry public immutable registry;

    // Publication ID trackers
    uint64 public unsafeHead;
    uint64 public safeHead;

    // URC-related parameters
    address public immutable slasher;
    uint256 public immutable requiredCollateralWei;

    // EIP-4788
    address private constant beaconRootsContract = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;
    uint256 private immutable GENESIS_TIMESTAMP;

    // attributes associated with the publication
    uint256 private constant METADATA = 0;
    uint256 private constant LAST_PUBLICATION = 1;
    uint256 private constant BLOB_REFERENCE = 2;
    uint256 private constant VALIDATOR_PUBKEY = 3;

    event NewSafeHead(uint64 indexed newSafeHead);

    constructor(
        address _publicationFeed,
        address _blobRefRegistry,
        address _registry,
        address _slasher,
        address _proposerFees,
        uint256 _inclusionDelay,
        uint256 _requiredCollateralWei,
        uint256 _genesisTimestamp
    ) DelayedInclusionStore(_inclusionDelay, _blobRefRegistry) {
        publicationFeed = IPublicationFeed(_publicationFeed);
        registry = IRegistry(_registry);
        slasher = _slasher;
        proposerFees = IProposerFees(_proposerFees);
        requiredCollateralWei = _requiredCollateralWei;
        GENESIS_TIMESTAMP = _genesisTimestamp;
    }

    // @notice Publish a new publication and update the heads
    // @param nBlobs The number of blobs being published
    // @param registrationProof The Merkle proof that msg.sender is registered with the URC
    // @param validatorProof The EIP-4788 proof that proves who the validator was at a given slot
    // @param unsafeHeader The PublicationHeader from the previous publication
    // @param unsafeAttributeHashes The attribute hashes of the previous publication
    // @param replaceUnsafeHead Whether to replace the unsafe head or update the safe head
    function publish(
        uint256 nBlobs,
        IRegistry.RegistrationProof calldata registrationProof,
        EIP4788.ValidatorProof calldata validatorProof,
        IPublicationFeed.PublicationHeader calldata unsafeHeader,
        bytes32[] calldata unsafeAttributeHashes,
        bool replaceUnsafeHead
    ) external payable {
        // Verify the proposer is allowed to publish
        _isAllowedProposer(registrationProof);

        // Publish the attributes
        (uint64 newPublicationId, Metadata memory metadata) =
            _publishAttributes(nBlobs, _hashBLSPubKey(registrationProof.registration.pubkey));

        // Update the heads
        (unsafeHead, safeHead) =
            _updateHeads(replaceUnsafeHead, newPublicationId, unsafeHeader, unsafeAttributeHashes, validatorProof);

        // Process delayed inclusions
        _forceInclusions(metadata);
    }

    function _buildBlobIndices(uint256 nBlobs) private pure returns (uint256[] memory blobIndices) {
        blobIndices = new uint256[](nBlobs);
        for (uint256 i; i < nBlobs; ++i) {
            blobIndices[i] = i;
        }
    }

    function _isAllowedProposer(IRegistry.RegistrationProof calldata registrationProof) internal view {
        // Get the URC's config
        IRegistry.Config memory config = registry.getConfig();

        // Get the data of the operator from the URC
        // This will revert if the proof is invalid
        IRegistry.OperatorData memory operator = registry.getVerifiedOperatorData(registrationProof);

        // Perform sanity checks on the operator's data
        require(operator.collateralWei >= requiredCollateralWei, "Insufficient collateral");

        require(operator.slashedAt == 0, "Operator has been slashed");

        // Verify operator has not unregistered
        if (operator.unregisteredAt != type(uint48).max) {
            require(block.number < operator.unregisteredAt + config.unregistrationDelay, "Operator unregistered");
        }

        // Get information about the operator's commitment to the rollup's specified slasher
        IRegistry.SlasherCommitment memory slasherCommitment =
            registry.getSlasherCommitment(registrationProof.registrationRoot, slasher);

        // Perform sanity checks on the slasher commitment
        require(slasherCommitment.optedOutAt < slasherCommitment.optedInAt, "Not opted into slasher");

        require(slasherCommitment.slashed == false, "Operator has been slashed");

        require(slasherCommitment.committer == msg.sender, "Wrong blob submitter address");

        require(block.number > slasherCommitment.optedInAt + config.optInDelay, "Too early to make commitments");

        // todo potentially check collateral history

        // todo other checks?
    }

    function _publishAttributes(uint256 nBlobs, bytes32 pubkeyHash)
        internal
        returns (uint64 _publicationId, Metadata memory metadata)
    {
        // Construct metadata attribute
        metadata =
            Metadata({anchorBlockId: unsafeHead, anchorBlockHash: blockhash(unsafeHead), isDelayedInclusion: false});
        require(metadata.anchorBlockHash != 0, "blockhash not found");

        // Construct publication attributes
        bytes[] memory attributes = new bytes[](4);
        attributes[METADATA] = abi.encode(metadata);
        attributes[LAST_PUBLICATION] = abi.encode(unsafeHead);
        attributes[BLOB_REFERENCE] = abi.encode(blobRefRegistry.getRef(_buildBlobIndices(nBlobs)));
        attributes[VALIDATOR_PUBKEY] = abi.encode(pubkeyHash);

        // Pay the publication fee
        (uint256 publicationFee,) = proposerFees.getCurrentFees();
        proposerFees.payPublicationFee{value: publicationFee}(msg.sender, false);

        // Publish the attributes and save the publication id
        _publicationId = uint64(publicationFeed.publish(attributes).id);
    }

    function _updateHeads(
        bool replaceUnsafeHead,
        uint64 newPublicationId,
        IPublicationFeed.PublicationHeader calldata unsafeHeader,
        bytes32[] calldata unsafeAttributeHashes,
        EIP4788.ValidatorProof calldata validatorProof
    ) internal returns (uint64 _unsafeHead, uint64 _safeHead) {
        // Validate the unsafe header matches what's in the publication feed
        // and that the header is for the unsafe head
        require(
            publicationFeed.validateHeader(unsafeHeader) && unsafeHeader.id == unsafeHead, "unsafeHeader is invalid"
        );

        // Verify the supplied attribute hashes match what's in the publication feed
        require(
            keccak256(abi.encode(unsafeAttributeHashes)) == unsafeHeader.attributesHash,
            "unsafeAttributeHashes are invalid"
        );

        // Ensure that publish is not called twice in the same block
        // The unsafeHead is updated every successful publish so this timestamp
        // should never be the same as the current block timestamp unless publish
        // is called more than once
        require(unsafeHeader.timestamp != block.timestamp, "publish called twice in the same block");

        // Verify the supplied validator proof is valid. Note this doesn't check
        // the validator public key during the slot, that's done below
        require(
            EIP4788.verifyValidatorProof(getBeaconBlockRootFromTimestamp(unsafeHeader.timestamp), validatorProof),
            "validator proof is invalid"
        );

        // Reconstruct the pubkeyhash by hashing it as the attribute was
        bytes32 _provenPubkeyHash = keccak256(abi.encode(validatorProof.validator[0]));

        if (replaceUnsafeHead) {
            // If the committed pubkeyhash doesn't match what was proven by the
            // validatorProof, it means the L1 proposer during that slot wasn't
            // the unsafeHead proposer, allowing the sender to replace it
            require(_provenPubkeyHash != unsafeAttributeHashes[VALIDATOR_PUBKEY], "unsafeHead should not be replaced");

            // Replace the unsafe head
            _unsafeHead = newPublicationId;

            // Keep the safe head the same
            _safeHead = safeHead;
        } else {
            // If the committed pubkeyhash matches what was proven by the
            // validatorProof, it means the L1 proposer during that slot was the
            // unsafeHead proposer, so we promote the unsafeHead to safeHead
            require(_provenPubkeyHash == unsafeAttributeHashes[VALIDATOR_PUBKEY], "unsafeHead should be replaced");

            // Update the safe head
            _safeHead = unsafeHead;
            emit NewSafeHead(_safeHead);

            // Replace the unsafe head
            _unsafeHead = newPublicationId;
        }
    }

    function _forceInclusions(Metadata memory metadata) internal {
        IDelayedInclusionStore.Inclusion[] memory inclusions = processDueInclusions();
        // unsafeHead is always the latest publication id
        uint64 _lastPublicationId = unsafeHead;
        metadata.isDelayedInclusion = true;

        (, uint256 delayedPublicationFee) = proposerFees.getCurrentFees();

        // Metadata is fixed for all inclusions
        bytes[] memory attributes = new bytes[](3);
        attributes[METADATA] = abi.encode(metadata);
        for (uint256 i; i < inclusions.length; ++i) {
            attributes[LAST_PUBLICATION] = abi.encode(_lastPublicationId);
            attributes[BLOB_REFERENCE] = abi.encode(inclusions[i]);

            // Pay the publication fee
            proposerFees.payPublicationFee{value: delayedPublicationFee}(msg.sender, true);

            // Publish the inclusion
            _lastPublicationId = uint64(publicationFeed.publish(attributes).id);

            // Update the safe head
            safeHead = _lastPublicationId;
            emit NewSafeHead(safeHead);
        }
    }

    // source: https://github.com/nerolation/slashing-proofoor/blob/main/src/SlashingProofoor.sol
    function getBeaconBlockRootFromTimestamp(uint256 timestamp) public returns (bytes32) {
        (bool ret, bytes memory data) = beaconRootsContract.call(bytes.concat(bytes32(timestamp)));
        require(ret);
        return bytes32(data);
    }

    // @notice Compress the BLS public key to size 48B then compute the hash tree root as saved in the beacon state
    function _hashBLSPubKey(BLS.G1Point memory validatorBLSPubKey) internal pure returns (bytes32 pubKeyHashTreeRoot) {
        // todo endianness is correct
        pubKeyHashTreeRoot = sha256(abi.encode(BLS.compress(validatorBLSPubKey)));
    }
}
