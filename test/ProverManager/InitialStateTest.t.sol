// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ProverManager} from "../../src/protocol/taiko_alethia/ProverManager.sol";
import {InitialState} from "./InitialState.t.sol";
import {InvariantTest} from "./InvariantTest.t.sol";

contract InitialStateTest is InitialState, InvariantTest {
    function test_InitialBalanceIsZero() public view {
        assertEq(proverManager.balances(deployer), 0, "Deployer has non-zero balance");
        assertEq(proverManager.balances(initialProver), 0, "Initial prover has non-zero balance");
    }

    function test_CurrentPeriodIsZero() public view {
        assertEq(proverManager.currentPeriodId(), 0, "Current period is not 1");
    }

    function test_PeriodZero() public view {
        ProverManager.Period memory p = proverManager.getPeriod(0);
        assertEq(p.prover, address(0), "Non-zero prover");
        assertEq(p.stake, 0, "Non-zero stake");
        assertEq(p.fee, 0, "Non-zero fee");
        assertEq(p.end, vm.getBlockTimestamp(), "Period does not end this block");
        assertEq(p.deadline, vm.getBlockTimestamp(), "Proving deadline is not this block");
        assertEq(p.pastDeadline, false, "pastDeadline is set");
    }

    function test_PeriodOne() public view {
        ProverManager.Period memory p = proverManager.getPeriod(1);
        assertEq(p.prover, initialProver, "Incorrect prover");
        assertEq(p.stake, LIVENESS_BOND, "Incorrect state");
        assertEq(p.fee, INITIAL_FEE, "Incorrect fee");
        assertEq(p.end, 0, "Period has end timestamp");
        assertEq(p.deadline, 0, "Period has proving deadline");
        assertEq(p.pastDeadline, false, "pastDeadline is set");
    }
}
