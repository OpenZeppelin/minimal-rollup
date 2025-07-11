// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UniversalTest} from "./UniversalTest.t.sol";
import {LibPercentage} from "src/libs/LibPercentage.sol";
import {LibProvingPeriod} from "src/libs/LibProvingPeriod.sol";

/// Represents states where the current timestamp is after the end of the current period
abstract contract CurrentPeriodIsOverTest is UniversalTest {
    function test_CurrentPeriodIsOver_payPublicationFee_shouldAdvancePeriod() public {
        _deposit(proposer, DEPOSIT_AMOUNT);
        uint256 initialPeriodId = proverManager.currentPeriodId();

        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, false);

        assertEq(proverManager.currentPeriodId(), initialPeriodId + 1, "Period is not advanced");
    }

    function test_CurrentPeriodIsOver_payPublicationFee_shouldDeductNextPeriodRegularFee() public {
        _deposit(proposer, DEPOSIT_AMOUNT);
        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId() + 1);

        uint256 balanceBefore = proverManager.balances(proposer);

        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, false);

        uint256 balanceAfter = proverManager.balances(proposer);

        assertEq(balanceBefore - balanceAfter, period.fee, "Regular fee was not deducted");
    }

    function test_CurrentPeriodIsOver_payPublicationFee_shouldDeductNextPeriodDelayedFee() public {
        _deposit(proposer, DEPOSIT_AMOUNT);
        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId() + 1);

        uint256 balanceBefore = proverManager.balances(proposer);

        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, true);

        uint256 balanceAfter = proverManager.balances(proposer);

        uint256 delayedFee = LibPercentage.scaleByPercentage(period.fee, period.delayedFeePercentage);
        assertEq(balanceBefore - balanceAfter, delayedFee, "Delayed fee was not deducted");
    }

    function test_CurrentPeriodIsOver_payPublicationFee_shouldNotTransferRegularFee() public {
        _deposit(proposer, DEPOSIT_AMOUNT);
        uint256 escrowedBefore = _currencyBalance(address(proverManager));

        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, false);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));

        assertEq(escrowedBefore, escrowedAfter, "Escrowed balance changed");
    }

    function test_CurrentPeriodIsOver_payPublicationFee_shouldNotTransferDelayedFee() public {
        _deposit(proposer, DEPOSIT_AMOUNT);
        uint256 escrowedBefore = _currencyBalance(address(proverManager));

        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, true);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));

        assertEq(escrowedBefore, escrowedAfter, "Escrowed balance changed");
    }

    function test_CurrentPeriodIsActive_getCurrentFees_shouldReturnFeesForNextPeriod() public view {
        uint256 periodId = proverManager.currentPeriodId() + 1;
        LibProvingPeriod.Period memory period = proverManager.getPeriod(periodId);
        (uint96 fee, uint96 delayedFee) = proverManager.getCurrentFees();
        assertEq(fee, period.fee, "Incorrect standard fee");
        assertEq(delayedFee, LibPercentage.scaleByPercentage(period.fee, period.delayedFeePercentage));
    }
}
