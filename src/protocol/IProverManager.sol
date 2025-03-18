// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {IPublicationFeed} from "./IPublicationFeed.sol";

interface IProverManager {
    /// @notice Bid to become the prover for the next period
    /// @param offeredFee The fee you are willing to charge for proving each publication
    function bid(uint256 offeredFee) external;

    /// @notice The current prover can signal exit to eventually pull out their liveness bond.
    function exit() external;

    /// @notice If there is no active prover, start a new period and become the new prover immediately
    /// @param fee The per-publication fee for the new period
    /// @dev Consider the scenario:
    ///   - a prover has exited or been evicted
    ///   - no prover has bid on the next period
    ///   - a publication is made, creating a new period with no prover and no fee
    /// At this point it is impossible to outbid for the prover because the fee is zero
    /// This function allows anyone to start a new period with a new fee. Note that the new prover will still need to
    // ensure the previous publications are proven before proving their own. Nevertheless, we start a new period so
    // they cannot be evicted based on publications that occurred before they agreed to prove
    function claimProvingVacancy(uint256 fee) external;

    /// @notice Evicts a prover that has been inactive, marking the prover for slashing
    /// @param publicationId The publication id that the caller is claiming is too old and hasn't been proven
    /// @param publicationHeader The publication header that the caller is claiming is too old and hasn't been proven
    /// @param lastProven The last proven checkpoint, which is used to show the publicationHeader is not proven
    /// TODO: we should save the actual checkpoint (not the hash) in CheckpointTracker so we can query it directly
    function evictProver(
        uint256 publicationId,
        IPublicationFeed.PublicationHeader calldata publicationHeader,
        ICheckpointTracker.Checkpoint calldata lastProven
    ) external;

    /// @notice Submits a proof for an open period
    /// @dev An open period is not necessarily the current period, it just means that the prover is within their
    /// deadline.
    /// @dev If the prover has finished all their publications for the period, they can also claim the fees and their
    /// liveness bond.
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param startPublicationHeader The start publication header
    /// @param endPublicationHeader The end publication header
    /// @param numPublications The number of publications to process. This is not implied by the start/end publication
    /// ids because there could be irrelevant publications.
    /// @param nextPublicationHeaderBytes Optional parameter that should only be sent when the prover has finished all
    /// their publications for the period.
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    /// @param periodId The id of the period for which the proof is submitted
    function proveOpenPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata startPublicationHeader,
        IPublicationFeed.PublicationHeader calldata endPublicationHeader,
        uint256 numPublications,
        bytes calldata nextPublicationHeaderBytes,
        bytes calldata proof,
        uint256 periodId
    ) external;

    /// @notice Called by a prover when the originally assigned prover is passed its deadline
    /// @dev This function should slash the prover and distribute their stake to compensate the new prover
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param startPublicationHeader The start publication header
    /// @param endPublicationHeader The end publication header
    /// @param numPublications The number of publications to process. This is not implied by the start/end publication
    /// ids because there could be irrelevant publications.
    /// @param nextPublicationHeader The next publication header. It should be after the period end
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    /// @param periodId The id of the period for which the proof is submitted
    function proveClosedPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata startPublicationHeader,
        IPublicationFeed.PublicationHeader calldata endPublicationHeader,
        uint256 numPublications,
        IPublicationFeed.PublicationHeader calldata nextPublicationHeader,
        bytes calldata proof,
        uint256 periodId
    ) external;

    /// @notice Returns the stake for a closed period to the prover
    /// @dev Only needed if the period was not finalized during its last proof.
    /// @dev This could occur if the prover did not specify a later publication (possibly because it did not exist at
    /// the time)
    /// @param periodId The id of the period to finalize
    /// @param lastProven The last proven checkpoint. TODO: we should save the actual checkpoint (not the hash) in
    /// CheckpointTracker so we can query it directly
    /// @param provenPublicationHeaderBytes Optional parameter if needed to demonstrate there is a proven publication
    /// after the period
    function finalizeClosedPeriod(
        uint256 periodId,
        ICheckpointTracker.Checkpoint calldata lastProven,
        bytes calldata provenPublicationHeaderBytes
    ) external;
}
