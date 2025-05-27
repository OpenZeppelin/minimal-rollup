// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "./ICheckpointTracker.sol";
import {IInbox} from "./IInbox.sol";

interface IProverManager {
    /// @notice Emitted when a prover bids to prove a period
    /// @param prover The address of the prover that made the bid
    /// @param periodId The period that the prover is bidding to prove
    /// @param fee The fee that the prover is willing to charge for proving each publication
    /// @param stake The stake that the prover is going to put as stake for the period
    event ProverOffer(address indexed prover, uint256 periodId, uint256 fee, uint256 stake);

    /// @notice Emitted when a prover is evicted from the prover role
    /// @param prover The address of the prover that was evicted
    /// @param evictor The address that evicted the prover
    /// @param periodEnd The end of the period that the prover was evicted from
    /// @param livenessBond The liveness bond that the prover had originally put up
    event ProverEvicted(address indexed prover, address indexed evictor, uint256 periodEnd, uint256 livenessBond);

    /// @notice Emitted when a prover exits the prover role
    /// @param prover The address of the prover that exited
    /// @param periodEnd The end of the period that the prover exited from
    /// @param provingDeadline The deadline for the prover to prove the period
    event ProverExited(address indexed prover, uint256 periodEnd, uint256 provingDeadline);

    /// @notice Emitted when a new period starts
    /// @param periodId The id of the new period
    event NewPeriod(uint256 periodId);

    /// @notice Bid to become the prover for the next period
    /// @param offeredFee The fee you are willing to charge for proving each publication
    function bid(uint96 offeredFee) external;

    /// @notice The current prover can signal exit to eventually pull out their liveness bond.
    function exit() external;

    /// @notice If there is no active prover, start a new period and become the new prover in the next block
    /// @param fee The per-publication fee for the new period
    /// @dev Consider the scenario:
    ///   - a prover has exited or been evicted
    ///   - no prover has bid on the next period
    ///   - a publication is made, creating a new period with no prover and no fee
    /// At this point it is impossible to outbid the prover because the fee is zero
    /// This function allows anyone to start a new period with a new fee. Note that the new prover will still need to
    // ensure the previous publications are proven before proving their own. Nevertheless, we start a new period so
    // they cannot be evicted based on publications that occurred before they agreed to prove
    function claimProvingVacancy(uint96 fee) external;

    /// @notice Evicts a prover that has been inactive, marking the prover for slashing
    /// @param publicationHeader The publication header that the caller is claiming is too old and hasn't been proven
    function evictProver(IInbox.PublicationHeader calldata publicationHeader) external;

    /// @notice Submits a proof.
    /// @dev If called after the period has passed its proving deadline, the caller becomes the prover for the
    /// period and some of the original prover's stake is burned
    /// @dev In either case the (possibly new) prover gets the fee for all proven publications
    /// @param start The initial checkpoint before the transition
    /// @param end The final checkpoint after the transition
    /// @param firstPub The first publication header in the transition. Note that since checkpoints refer to the
    /// publication they follow, this should have an id `start.publicationId + 1`
    /// @param lastPub The last publication header in the transition
    /// @param numDelayedPublications The number of delayed publications from the total number of publications being
    /// proven
    /// @param proof Arbitrary data passed to the `verifier` contract to confirm the transition validity
    /// @param periodId The id of the period for which the proof is submitted
    function prove(
        ICheckpointTracker.Checkpoint calldata start,
        ICheckpointTracker.Checkpoint calldata end,
        IInbox.PublicationHeader calldata firstPub,
        IInbox.PublicationHeader calldata lastPub,
        uint256 numDelayedPublications,
        bytes calldata proof,
        uint256 periodId
    ) external;

    /// @notice Returns the stake for a past period to the prover
    /// @param periodId The id of the period to finalize
    /// @param provenPublication A publication that the caller is claiming has been proven and is after the period end
    /// @dev If there is a proven publication after the period, it implies the whole period has been proven.
    /// @dev We assume there will always be a suitable proven publication.
    function finalizePastPeriod(uint256 periodId, IInbox.PublicationHeader calldata provenPublication) external;
}

interface IERC20Depositor {
    /// @notice Deposit tokens into the contract.
    function deposit(uint256 amount) external;
}

interface IETHDepositor {
    /// @notice Deposit ETH into the contract.
    function deposit() external payable;
}
