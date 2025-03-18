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

    /// @notice If there is no active prover, start a new period and become the new prover in the next block
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

    /// @notice Submits a proof.
    /// @dev If called after the proof deadline, the caller becomes the new prover and some of the original prover's
    /// stake is burned
    /// @dev In either case the (possibly new) prover gets the fee for all proven publications
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param startPublicationHeader The start publication header
    /// @param endPublicationHeader The end publication header
    /// @param numPublications The number of publications to process. This is not implied by the start/end publication
    /// ids because there could be irrelevant publications.
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    /// @param periodId The id of the period for which the proof is submitted
    function prove(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata startPublicationHeader,
        IPublicationFeed.PublicationHeader calldata endPublicationHeader,
        uint256 numPublications,
        bytes calldata proof,
        uint256 periodId
    ) external;

    /// @notice Returns the stake for a closed period to the prover
    /// @param periodId The id of the period to finalize
    /// @param lastProven The last proven checkpoint. TODO: we should save the actual checkpoint (not the hash) in
    /// CheckpointTracker so we can query it directly
    /// @param provenPublication A publication after the period that has been proven
    /// @dev If there is a proven publication after the period, it implies the whole period has been proven.
    /// @dev We assume there will always be a suitable (and timely) proven publication.
    function finalizeClosedPeriod(
        uint256 periodId,
        ICheckpointTracker.Checkpoint calldata lastProven,
        IPublicationFeed.PublicationHeader calldata provenPublication
    ) external;
}
