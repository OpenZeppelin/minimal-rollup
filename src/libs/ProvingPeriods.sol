// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev A bidded period is a time window in which a prover can post proofs for state transitions.
///
/// A period is economically protected by a liveness bond the prover has to stake. Its purpose
/// is to disincentivize the prover from not posting a proof.
///
/// Each period has the following properties:
///
/// - `prover`: The address of the prover with the rights to post proofs during the period if active.
/// - `start`: Timestamp when the period becomes active. 0 means the period is not scheduled.
/// - `deadline`: Timestamp at which the prover becomes evictable if no proof is posted.
/// - `end`: Timestamp when the period ends. 0 means the period is still active.
/// - `stake`: The amount of ETH the prover has to deposit as a liveness bond.
/// - `accumulatedFee`: The total amount of fees accumulated in the period.
/// - `offeredFee`: The fee the prover is willing to charge for proving each publication.
library ProvingPeriods {
    struct Period {
        // slot 0
        address prover;
        uint48 start;
        uint48 deadline;
        // slot 1
        uint48 end;
        uint80 stake; // Up to ~1,208,925.688 ETH
        uint64 accumulatedFee; // Up to ~18.44 ETH
        uint64 offeredFee; // Up to ~18.44 ETH
    }

    /// @notice The period has at least one bid.
    function isBidded(Period storage period) internal view returns (bool) {
        return period.prover != address(0);
    }

    /// @notice The period is active (i.e. right to post proofs are for the registered prover).
    function isActive(Period storage period) internal view returns (bool) {
        return isStarted(period) && !isEnded(period);
    }

    /// @notice The period has started.
    function isStarted(Period storage period) internal view returns (bool) {
        return period.start != 0 && SafeCast.toUint48(block.timestamp) >= period.start;
    }

    /// @notice The period has ended.
    function isEnded(Period storage period) internal view returns (bool) {
        return period.end != 0 && SafeCast.toUint48(block.timestamp) >= period.end;
    }

    /// @notice The current prover can be evicted.
    function isEvictable(Period storage period) internal view returns (bool) {
        return period.deadline != 0 && SafeCast.toUint48(block.timestamp) >= period.deadline;
    }

    /// @notice Sets the moment the next period starts with a deadline after the prover can be evicted if no proof is
    /// posted.
    function scheduleStartAfterDelayWithDeadline(Period storage period, uint48 delay, uint48 provingDeadline)
        internal
    {
        uint48 start = SafeCast.toUint48(block.timestamp) + delay;
        period.start = start;
        period.deadline = start + provingDeadline;
    }

    /// @notice Sets the moment the current period ends after a delay.
    function scheduleEnd(Period storage period) internal returns (uint256) {
        uint48 periodEnd = SafeCast.toUint48(block.timestamp);
        period.end = periodEnd;
        // Respect the previous deadline if set
        // uint48 cast is safe because both values are uint48
        uint48 newDeadline = uint48(Math.min(period.deadline, periodEnd));
        period.deadline = newDeadline == 0 ? periodEnd : newDeadline;
        return periodEnd;
    }
}
