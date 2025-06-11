// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ProverManager} from "../../src/protocol/taiko_alethia/ProverManager.sol";
import {InitialState} from "./InitialState.t.sol";

/// This contract contains invariants that should hold in every state
/// It can be inherited by any Test contract to run all tests in that state
abstract contract InvariantTest is InitialState {
    function test_Invariant_PeriodAfterNextIsUnused() public view {
        uint256 currentPeriod = proverManager.currentPeriodId();
        ProverManager.Period memory p = proverManager.getPeriod(currentPeriod + 2);
        assertEq(p.prover, address(0), "prover non-zero");
        assertEq(p.stake, 0, "stake non-zero");
        assertEq(p.fee, 0, "fee non-zero");
        assertEq(p.end, 0, "end non-zero");
        assertEq(p.deadline, 0, "deadline non-zero");
        assertEq(p.pastDeadline, false, "pastDeadline set");
    }

    function test_Invariant_DeadlineNeverBeforePeriodEnd() public view {
        uint256 nextPeriod = proverManager.currentPeriodId() + 1;
        ProverManager.Period memory p;
        for (uint256 i = 0; i <= nextPeriod; i++) {
            p = proverManager.getPeriod(i);
            assertGe(p.deadline, p.end);
        }
    }

    function test_Invariant_NextPeriodIsOpen() public view {
        uint256 nextPeriod = proverManager.currentPeriodId() + 1;
        ProverManager.Period memory p = proverManager.getPeriod(nextPeriod);
        assertEq(p.end, 0, "next period is closed");
    }

    function test_Invariant_PeriodsAreInOrder() public view {
        uint256 currentPeriod = proverManager.currentPeriodId();
        ProverManager.Period memory previous = proverManager.getPeriod(0);
        ProverManager.Period memory next;
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
        ProverManager.Period memory previous = proverManager.getPeriod(currentPeriod - 1);
        assertGt(vm.getBlockTimestamp(), previous.end, "previous period not past");
    }
}
