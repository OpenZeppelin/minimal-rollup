// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {ICommitmentStore} from "./ICommitmentStore.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";
import {IVerifier} from "./IVerifier.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract CheckpointTracker is ICheckpointTracker {
    using SafeCast for uint256;
    /// @notice The current proven checkpoint representing the latest verified state of the rollup
    /// @dev Previous checkpoints are not stored here but are synchronized to the `SignalService`
    /// @dev A checkpoint commitment is any value (typically a state root) that uniquely identifies
    /// the state of the rollup at a specific point in time
    /// @dev We store the actual checkpoint(not the hash) to avoid race conditions when closing a period or evicting a
    /// prover(https://github.com/OpenZeppelin/minimal-rollup/pull/77#discussion_r2002192018)

    Checkpoint private _provenCheckpoint;

    IPublicationFeed public immutable publicationFeed;
    IVerifier public immutable verifier;
    ICommitmentStore public immutable commitmentStore;
    address public proverManager;

    /// @param _genesis the checkpoint commitment describing the initial state of the rollup
    /// @param _publicationFeed the input data source that updates the state of this rollup
    /// @param _verifier a contract that can verify the validity of a transition from one checkpoint to another
    /// @param _proverManager contract responsible for managing the prover auction
    /// @param _commitmentStore contract responsible storing historical commitments
    constructor(
        bytes32 _genesis,
        address _publicationFeed,
        address _verifier,
        address _proverManager,
        address _commitmentStore
    ) {
        // set the genesis checkpoint commitment of the rollup - genesis is trusted to be correct
        require(_genesis != 0, "genesis checkpoint commitment cannot be 0");

        publicationFeed = IPublicationFeed(_publicationFeed);
        verifier = IVerifier(_verifier);
        commitmentStore = ICommitmentStore(_commitmentStore);
        proverManager = _proverManager;
        Checkpoint memory genesisCheckpoint = Checkpoint({publicationId: 0, commitment: _genesis});
        _provenCheckpoint = genesisCheckpoint;
        emit CheckpointUpdated(genesisCheckpoint);
    }

    /// @inheritdoc ICheckpointTracker
    function proveTransition(
        Checkpoint calldata start,
        Checkpoint calldata end,
        uint256 numPublications,
        bytes calldata proof
    ) external {
        require(
            proverManager == address(0) || msg.sender == proverManager, "Only the prover manager can call this function"
        );

        require(end.commitment != 0, "Checkpoint commitment cannot be 0");

        require(
            start.publicationId == _provenCheckpoint.publicationId && start.commitment == _provenCheckpoint.commitment,
            "Start checkpoint must be the latest proven checkpoint"
        );

        require(start.publicationId < end.publicationId, "End publication must be after the last proven publication");

        bytes32 startPublicationHash = publicationFeed.getPublicationHash(start.publicationId);
        bytes32 endPublicationHash = publicationFeed.getPublicationHash(end.publicationId);
        require(endPublicationHash != 0, "End publication does not exist");

        verifier.verifyProof(
            startPublicationHash, endPublicationHash, start.commitment, end.commitment, numPublications, proof
        );

        _provenCheckpoint = end;
        emit CheckpointUpdated(end);

        // Stores the state of the other chain
        commitmentStore.storeCommitment(end.publicationId, end.commitment);
    }

    function getProvenCheckpoint() external view returns (Checkpoint memory) {
        return _provenCheckpoint;
    }
}
