// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev A bidded period is a time window in which a prover can post proofs for state transitions.
///
/// A period is economically protected by a liveness bond the prover has to stake. Its purpose
/// is to disincentivize the prover from not posting a proof.
///
/// Each period has the following properties:
///
/// - `prover`: The address of the prover that won the bid for the period.
/// - `end`: The timestamp when the period ends. 0 means the period is not active.
/// - `deadline`: Timestamp at which the prover becomes evictable if no proof is posted.
/// - `stake`: The amount of ETH the prover has to deposit as a liveness bond.
/// - `accumulatedFee`: The total amount of fees accumulated in the period.
/// - `offeredFee`: The fee the prover is willing to charge for proving each publication.
library LibBiddedPeriod {
    struct BiddedPeriod {
        // slot 0
        address prover;
        uint48 start;
        uint48 deadline;
        // slot 1
        uint48 end;
        uint208 stake;
        // slot 2
        uint128 accumulatedFee;
        uint128 offeredFee;
    }

    error InsufficientBalance();

    /// @notice The period has at least one bid.
    function isBidded(BiddedPeriod storage period) internal view returns (bool) {
        return period.prover != address(0);
    }

    /// @notice The period is active (i.e. right to post proofs are for the registered prover).
    function isActive(BiddedPeriod storage period) internal view returns (bool) {
        return isStarted(period) && !isEnded(period);
    }

    function isStarted(BiddedPeriod storage period) internal view returns (bool) {
        return period.start != 0 && SafeCast.toUint48(block.timestamp) >= period.start;
    }

    /// @notice The period has ended.
    function isEnded(BiddedPeriod storage period) internal view returns (bool) {
        return period.end != 0 && SafeCast.toUint48(block.timestamp) >= period.end;
    }

    /// @notice The period
    function scheduleStartAfterDelayWithDeadline(BiddedPeriod storage period, uint48 delay, uint48 provingDeadline)
        internal
    {
        uint48 start = SafeCast.toUint48(block.timestamp) + delay;
        period.start = start;
        period.deadline = start + provingDeadline;
    }

    function scheduleEndAfterDelayWithDeadline(BiddedPeriod storage period, uint48 delay, uint48 provingDeadline)
        internal
        returns (uint256)
    {
        uint48 periodEnd = SafeCast.toUint48(block.timestamp) + delay;
        uint48 _provingDeadline = periodEnd + provingDeadline;
        period.end = periodEnd;
        period.deadline = _provingDeadline;
        return periodEnd;
    }
}
