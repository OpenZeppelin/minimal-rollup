// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// Each proving period is defined by
/// - the _prover_ address that must post proofs for any publications received during this period
/// - the standard proving _fee_ that the prover charges per publication in this period
/// - the delayed proving fee that the prover charges per delayed publication in this period
///     - this is defined as a percentage (_delayedFeePercentage_) of the standard proving fee
/// The prover must lock some _stake_ that can be slashed if they fail to post a proof in a timely manner.
/// Proving periods are open-ended, meaning that they can be Open for an indefinite amount of time.
/// The period is Closed when the prover is outbid, chooses to leave, or is evicted for failing to prove.
/// At this point, the _end_ timestamp is set but the period is still Active. The prover is still required to
/// prove any publications received until the end timestamp is reached, when the period is Complete.
/// All publications in the period must be proven by the _deadline_, which should be after the end timestamp.
/// The prover can then withdraw their remaining stake, and the period is Finalized.
/// If a prover misses the deadline, anyone can prove outstanding publications on their behalf. In this case, the
/// _pastDeadline_ flag is set and the address that completes the outstanding proofs receives a fraction of the stake.
library LibProvingPeriod {
    struct Period {
        // SLOT 1
        address prover;
        uint96 stake;
        // SLOT 2
        // the fee that the prover is willing to charge for proving each publication
        uint96 fee;
        // the percentage (with two decimals precision) of the fee that is charged for delayed publications.
        uint16 delayedFeePercentage;
        // the timestamp of the end of the period. Default to zero while the period is open.
        uint40 end;
        // the time by which the prover needs to submit a proof
        uint40 deadline;
        // whether the proof came after the deadline
        bool pastDeadline;
    }

    /// @notice The period has an end timestamp in the past
    function isComplete(Period storage period) internal view returns (bool) {
        uint40 periodEnd = period.end;
        return periodEnd != 0 && block.timestamp > periodEnd;
    }
}
