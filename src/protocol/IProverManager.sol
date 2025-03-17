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

    /// @notice Evicts a prover that has been inactive, marking the prover for slashing
    /// @param publicationId The publication id that the caller is claiming is too old and hasn't been proven
    /// @param publicationHeader The publication header that the caller is claiming is too old and hasn't been proven
    /// @param lastProven The last proven checkpoint, which is used to should the publicationHeader is not proven
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
    /// @param nextPublicationHeaderBytes Optional parameter that should only be sent when the prover has finished all
    /// their publications for the period.
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    /// @param periodId The id of the period for which the proof is submitted
    function proveOpenPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader calldata startPublicationHeader,
        IPublicationFeed.PublicationHeader calldata endPublicationHeader,
        bytes calldata nextPublicationHeaderBytes,
        bytes calldata proof,
        uint256 periodId
    ) external;

    /// @notice Called by a prover when the originally assigned prover is passed its deadline
    /// @dev This function should slash the prover and distribute their stake to compensate the new prover
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param publicationHeadersToProve The chain of publication headers to prove
    /// @param nextPublicationHeader The next publication header. It should be after the period end
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    /// @param periodId The id of the period for which the proof is submitted
    function proveClosedPeriod(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IPublicationFeed.PublicationHeader[] calldata publicationHeadersToProve,
        IPublicationFeed.PublicationHeader calldata nextPublicationHeader,
        bytes calldata proof,
        uint256 periodId
    ) external;
}
