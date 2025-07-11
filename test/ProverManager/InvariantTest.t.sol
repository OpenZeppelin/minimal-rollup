// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {InitialState} from "./InitialState.t.sol";
import {LibProvingPeriod} from "src/libs/LibProvingPeriod.sol";

/// This contract contains invariants that should hold in every state
/// It can be inherited by any Test contract to run all tests in that state
abstract contract InvariantTest is InitialState {
    function test_Invariant_PeriodAfterNextIsUnused() public view {
        uint256 currentPeriod = proverManager.currentPeriodId();
        LibProvingPeriod.Period memory p = proverManager.getPeriod(currentPeriod + 2);
        assertEq(p.prover, address(0), "Prover is set");
        assertEq(p.stake, 0, "Stake is set");
        assertEq(p.fee, 0, "Fee is set");
        assertEq(p.delayedFeePercentage, 0, "Delayed fee percentage is set");
        assertEq(p.end, 0, "End is set");
        assertEq(p.deadline, 0, "Deadline is set");
        assertEq(p.pastDeadline, false, "Period has missed deadline");
    }

    function test_Invariant_DeadlineNeverBeforePeriodEnd() public view {
        uint256 nextPeriod = proverManager.currentPeriodId() + 1;
        LibProvingPeriod.Period memory p;
        for (uint256 i = 0; i <= nextPeriod; i++) {
            p = proverManager.getPeriod(i);
            assertGe(p.deadline, p.end);
        }
    }

    function test_Invariant_NextPeriodIsOpen() public view {
        uint256 nextPeriod = proverManager.currentPeriodId() + 1;
        LibProvingPeriod.Period memory p = proverManager.getPeriod(nextPeriod);
        assertEq(p.end, 0, "Next period is closed");
    }

    function test_Invariant_PeriodsAreInOrder() public view {
        uint256 currentPeriod = proverManager.currentPeriodId();
        LibProvingPeriod.Period memory previous = proverManager.getPeriod(0);
        LibProvingPeriod.Period memory next;
        // stop at previous period because current period may not have end timestamp
        for (uint256 i = 1; i < currentPeriod; i++) {
            next = proverManager.getPeriod(i);
            assertGe(next.end, previous.end);
            previous = next;
        }
    }

    function test_Invariant_TimestampAfterPreviousPeriod() public view {
        uint256 currentPeriod = proverManager.currentPeriodId();
        if (currentPeriod == 0) return;
        LibProvingPeriod.Period memory previous = proverManager.getPeriod(currentPeriod - 1);
        assertGt(vm.getBlockTimestamp(), previous.end, "Previous period is not past");
    }
}
