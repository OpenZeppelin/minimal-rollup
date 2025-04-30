// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {LibPercentage} from "../libs/LibPercentage.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

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
    using LibPercentage for uint96;
    using SafeCast for uint256;

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
        // the time by which the prover needs to submit the final proof
        uint40 deadline;
        // whether the final proof came after the deadline
        bool pastDeadline;
    }

    /// @notice Initializes the period with the given parameters.
    /// @dev The _end_ and _deadline_ default to zero. The _pastDeadline` flag defaults to false.
    /// @dev This can be called multiple times to set the latest bid while the auction is ongoing.
    function init(Period storage period, address prover, uint96 fee, uint16 delayedFeePercentage, uint96 stake)
        internal
    {
        require(prover != address(0), "Prover cannot be zero address");
        period.prover = prover;
        period.fee = fee;
        period.delayedFeePercentage = delayedFeePercentage;
        period.stake = stake;
    }

    /// @notice Whether the period has been initialized
    function isInitialized(Period storage period) internal view returns (bool) {
        return period.prover != address(0);
    }

    /// @notice The period has an end timestamp in the past
    function isComplete(Period storage period) internal view returns (bool) {
        uint40 periodEnd = period.end;
        return periodEnd != 0 && block.timestamp > periodEnd;
    }

    /// @notice The period fee, scaled by `delayedFeePercentage` if the publication is delayed
    function publicationFee(Period storage period, bool isDelayed) internal view returns (uint96) {
        return isDelayed ? period.fee.scaleBy(period.delayedFeePercentage, LibPercentage.PERCENT) : period.fee;
    }

    /// @notice The period has no end timestamp
    function isOpen(Period storage period) internal view returns (bool) {
        return period.end == 0;
    }

    /// @notice The timestamp is not after the end of the period
    function isNotBefore(Period storage period, uint256 timestamp) internal view returns (bool) {
        return isOpen(period) || timestamp.toUint40() <= period.end;
    }

    /// @notice The period has a deadline timestamp in the past
    function isDeadlinePassed(Period storage period) internal view returns (bool) {
        return block.timestamp > period.deadline && period.deadline != 0;
    }

    /// @dev Sets the period's end and deadline timestamps
    /// @param period The period to finalize
    /// @param endDelay The duration (from now) when the period will end
    /// @param provingWindow The duration that proofs can be submitted after the end of the period
    /// @return end The period's end timestamp
    /// @return deadline The period's deadline timestamp
    function close(Period storage period, uint40 endDelay, uint40 provingWindow)
        internal
        returns (uint40 end, uint40 deadline)
    {
        end = block.timestamp.toUint40() + endDelay;
        deadline = end + provingWindow;
        period.end = end;
        period.deadline = deadline;
    }

    /// @notice slash the penalty from the period's stake
    function slash(Period storage period, uint96 penalty) internal {
        period.stake -= penalty;
    }
}
