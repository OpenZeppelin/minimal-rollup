// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UniversalTest} from "./UniversalTest.t.sol";
import {LibProvingPeriod} from "src/libs/LibProvingPeriod.sol";
import {BaseProverManager} from "src/protocol/BaseProverManager.sol";

import {IInbox} from "src/protocol/IInbox.sol";
import {IProverManager} from "src/protocol/IProverManager.sol";

/// Represents states where the current period is open and has no prover
abstract contract CurrentPeriodIsVacant is UniversalTest {
    // This is a sanity check to ensure we're in the expected state
    function test_CurrentPeriodIsVacant_confirmPreconditions() public view {
        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId());
        assertEq(period.end, 0, "Period is not open");
        assertEq(period.prover, address(0), "Period has prover");
        // this is not part of the definition of "vacant" but it should be impossible to get into a situation
        // where there is a fee and no prover
        assertEq(period.fee, 0, "Period has non-zero fee");
    }

    function test_CurrentPeriodIsVacant_payPublicationFee_shouldChargeNoRegularFee() public {
        uint256 balanceBefore = proverManager.balances(proposer);
        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, false);
        uint256 balanceAfter = proverManager.balances(proposer);

        assertEq(balanceBefore, balanceAfter, "Proposer balance changed");
    }

    function test_CurrentPeriodIsVacant_payPublicationFee_shouldChargeNoDelayedFee() public {
        uint256 balanceBefore = proverManager.balances(proposer);
        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, true);
        uint256 balanceAfter = proverManager.balances(proposer);

        assertEq(balanceBefore, balanceAfter, "Proposer balance changed");
    }

    function test_CurrentPeriodIsVacant_bid_shouldRevertOnZeroBid() public {
        _deposit(proverA, DEPOSIT_AMOUNT);
        vm.prank(proverA);
        vm.expectRevert(BaseProverManager.OfferedFeeTooHigh.selector);
        proverManager.bid(0);
    }

    function test_CurrentPeriodIsVacant_evictProver_shouldRevert() public {
        IInbox.PublicationHeader memory header;
        header.timestamp = vm.getBlockTimestamp() - proverManager.livenessWindow() - 1;
        header.id = checkpointTracker.LAST_PROVEN_ID() + 1;

        vm.prank(evictor);
        vm.expectRevert(BaseProverManager.PeriodNotInitialized.selector);
        proverManager.evictProver(header);
    }

    function test_CurrentPeriodIsVacant_claimProvingVacancy_shouldClosePeriod() public {
        _deposit(proverA, DEPOSIT_AMOUNT);
        vm.prank(proverA);
        proverManager.claimProvingVacancy(initialFee);

        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId());
        assertEq(period.end, vm.getBlockTimestamp(), "End timestamp set incorrectly");
        assertEq(period.deadline, period.end, "Proving deadline does not match end timestamp");
    }

    function test_CurrentPeriodIsVacant_claimProvingVacancy_shouldLeaveOtherFieldsUnchanged() public {
        _deposit(proverA, DEPOSIT_AMOUNT);
        uint256 periodId = proverManager.currentPeriodId();
        LibProvingPeriod.Period memory periodBefore = proverManager.getPeriod(periodId);

        vm.prank(proverA);
        proverManager.claimProvingVacancy(initialFee);

        LibProvingPeriod.Period memory periodAfter = proverManager.getPeriod(periodId);

        assertEq(periodBefore.prover, periodAfter.prover, "Prover changed");
        assertEq(periodBefore.stake, periodAfter.stake, "Stake changed");
        assertEq(periodBefore.fee, periodAfter.fee, "Fee changed");
        assertEq(periodBefore.delayedFeePercentage, periodAfter.delayedFeePercentage, "Delayed fee changed");
        assertEq(periodBefore.pastDeadline, false, "Period had missed deadline");
        assertEq(periodAfter.pastDeadline, false, "Period has missed deadline");
    }

    function test_CurrentPeriodIsVacant_claimProvingVacancy_shouldDeductLivenessBond() public {
        _deposit(proverA, DEPOSIT_AMOUNT);
        uint256 balanceBefore = proverManager.balances(proverA);

        vm.prank(proverA);
        proverManager.claimProvingVacancy(initialFee);

        uint256 balanceAfter = proverManager.balances(proverA);
        assertEq(balanceAfter, balanceBefore - proverManager.livenessBond(), "Balance deducted incorrectly");
    }

    function test_CurrentPeriodIsVacant_claimProvingVacancy_shouldInitializeNextPeriod() public {
        _deposit(proverA, DEPOSIT_AMOUNT);
        vm.prank(proverA);
        proverManager.claimProvingVacancy(initialFee);

        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId() + 1);
        assertEq(period.prover, proverA, "Prover set incorrectly");
        assertEq(period.stake, proverManager.livenessBond(), "Stake set incorrectly");
        assertEq(period.fee, initialFee, "Fee set incorrectly");
        assertEq(period.delayedFeePercentage, proverManager.delayedFeePercentage(), "Delayed fee set incorrectly");
        assertEq(period.end, 0, "Next period is closed");
        assertEq(period.deadline, 0, "Next period has deadline");
        assertEq(period.pastDeadline, false, "Next period has missed deadline");
    }

    function test_CurrentPeriodIsVacant_claimProvingVacancy_shouldEmitEvent() public {
        _deposit(proverA, DEPOSIT_AMOUNT);
        uint256 nextPeriodId = proverManager.currentPeriodId() + 1;
        uint96 bond = proverManager.livenessBond();

        vm.prank(proverA);
        vm.expectEmit();
        emit IProverManager.ProverVacancyClaimed(proverA, nextPeriodId, initialFee, bond);
        proverManager.claimProvingVacancy(initialFee);
    }

    function test_CurrentPeriodIsVacant_claimProvingVacancy_shouldAllowZeroFee() public {
        _deposit(proverA, DEPOSIT_AMOUNT);
        vm.prank(proverA);
        proverManager.claimProvingVacancy(0);

        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId() + 1);
        assertEq(period.prover, proverA, "Prover set incorrectly");
        assertEq(period.fee, 0, "Fee set incorrectly");
    }
}
