// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";
import {IVerifier} from "./IVerifier.sol";

contract CheckpointTracker is ICheckpointTracker {
    /// @notice The current proven checkpoint representing the latest verified state of the rollup
    /// @dev Previous checkpoints are not stored here but are synchronized to the `SignalService`
    /// @dev A checkpoint commitment is any value (typically a state root) that uniquely identifies
    /// the state of the rollup at a specific point in time
    /// @dev We store the actual checkpoint(not the hash) to avoid race conditions when closing a period or evicting a
    /// prover(https://github.com/OpenZeppelin/minimal-rollup/pull/77#discussion_r2002192018)
    Checkpoint private _provenCheckpoint;

    IPublicationFeed public immutable publicationFeed;
    IVerifier public immutable verifier;
    address public proverManager;

    /// @param _genesis the checkpoint commitment describing the initial state of the rollup
    /// @param _publicationFeed the input data source that updates the state of this rollup
    /// @param _verifier a contract that can verify the validity of a transition from one checkpoint to another
    /// @param _proverManager contract responsible for managing the prover auction
    constructor(bytes32 _genesis, address _publicationFeed, address _verifier, address _proverManager) {
        // set the genesis checkpoint commitment of the rollup - genesis is trusted to be correct
        require(_genesis != 0, "genesis checkpoint commitment cannot be 0");

        publicationFeed = IPublicationFeed(_publicationFeed);
        verifier = IVerifier(_verifier);
        proverManager = _proverManager;
        Checkpoint memory genesisCheckpoint = Checkpoint({publicationId: 0, commitment: _genesis});
        _provenCheckpoint = genesisCheckpoint;
        emit CheckpointUpdated(genesisCheckpoint);
    }

    /// @inheritdoc ICheckpointTracker
    /// @dev This function does not use the `start` checkpoint since we don't support parallel transitions.
    function proveTransition(
        Checkpoint calldata,
        Checkpoint calldata end,
        uint256 numPublications,
        uint256 numDelayedPublications,
        bytes calldata proof
    ) external {
        require(
            proverManager == address(0) || msg.sender == proverManager, "Only the prover manager can call this function"
        );

        require(end.commitment != 0, "Checkpoint commitment cannot be 0");
        require(
            numDelayedPublications <= numPublications,
            "Number of delayed publications cannot be greater than the total number of publications"
        );
        bytes32 startPublicationHash = publicationFeed.getPublicationHash(_provenCheckpoint.publicationId);
        bytes32 endPublicationHash = publicationFeed.getPublicationHash(end.publicationId);
        require(endPublicationHash != 0, "End publication does not exist");

        verifier.verifyProof(
            startPublicationHash,
            endPublicationHash,
            _provenCheckpoint.commitment,
            end.commitment,
            numPublications,
            numDelayedPublications,
            proof
        );

        _provenCheckpoint = end;
        emit CheckpointUpdated(end);
    }

    function getProvenCheckpoint() external view returns (Checkpoint memory) {
        return _provenCheckpoint;
    }
}
