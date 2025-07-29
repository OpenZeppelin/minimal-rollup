// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ICheckpointTracker {
    struct Checkpoint {
        uint256 publicationId;
        /// @dev A commitment can be anything that uniquely represents the state of the rollup
        /// @dev We recommend using the `keccak256(stateRoot, blockHash)` or similar to ensure both uniqueness and being
        /// able to verify messages across chains
        bytes32 commitment;
        /// @dev The cumulative number of delayed publications up to this checkpoint (since genesis)
        /// @dev This enables computing the delayed publications between two checkpoints
        uint256 totalDelayedPublications;
    }

    /// @notice Emitted when the latest commitment is saved
    /// @param publicationId the publication ID of the latest proven checkpoint
    /// @param commitment the commitment of the latest proven checkpoint
    event CommitmentSaved(uint256 indexed publicationId, bytes32 commitment);

    /// @notice Emitted when ProverManager is initialised
    /// @param proverManager The address of the ProverManager contract
    event ProverManagerInitialised(address indexed proverManager);

    /// @return _ The last proven publication ID
    function provenPublicationId() external view returns (uint256);

    /// @notice Initialize the proverManager address
    /// @param _proverManager The address of the ProverManager contract
    function initializeProverManager(address _proverManager) external;

    /// @notice Verifies a transition between two checkpoints. Update the latest `provenCheckpoint` if possible
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    /// @return _ The number of new publications that were proven. Note this may be lower than end.publicationId -
    /// start.publicationId because this proof may overlap with some proven checkpoints.
    /// @return _ The number of new delayed publications that were proven.
    function proveTransition(Checkpoint calldata start, Checkpoint calldata end, bytes calldata proof)
        external
        returns (uint256, uint256);
}
