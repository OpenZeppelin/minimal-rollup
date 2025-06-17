// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UniversalTest} from "./UniversalTest.t.sol";
import {LibPercentage} from "src/libs/LibPercentage.sol";
import {LibProvingPeriod} from "src/libs/LibProvingPeriod.sol";

/// Represents states where the current timestamp is not after the end of the current period
/// (or the current period is open with no end set).
abstract contract CurrentPeriodIsActiveTest is UniversalTest {
    function setUp() public virtual override {
        super.setUp();
        _prepareForDeposit(proposer, DEPOSIT_AMOUNT);
        _executeDeposit(proposer, DEPOSIT_AMOUNT);
    }

    function test_CurrentPeriodIsActive_payPublicationFee_shouldDeductRegularFee() public {
        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId());

        uint256 balanceBefore = proverManager.balances(proposer);

        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, false);

        uint256 balanceAfter = proverManager.balances(proposer);

        assertEq(balanceAfter - balanceBefore, period.fee, "Regular fee was not deducted");
    }

    function test_CurrentPeriodIsActive_payPublicationFee_shouldDeductDelayedFee() public {
        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId());

        uint256 balanceBefore = proverManager.balances(proposer);

        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, true);

        uint256 balanceAfter = proverManager.balances(proposer);

        uint256 delayedFee = LibPercentage.scaleByPercentage(period.fee, period.delayedFeePercentage);
        assertEq(balanceAfter - balanceBefore, delayedFee, "Delayed fee was not deducted");
    }

    function test_CurrentPeriodIsActive_payPublicationFee_shouldNotTransferRegularFee() public {
        uint256 escrowedBefore = _currencyBalance(address(proverManager));

        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, false);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));

        assertEq(escrowedBefore, escrowedAfter, "Escrowed balance changed");
    }

    function test_CurrentPeriodIsActive_payPublicationFee_shouldNotTransferDelayedFee() public {
        uint256 escrowedBefore = _currencyBalance(address(proverManager));

        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, true);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));

        assertEq(escrowedBefore, escrowedAfter, "Escrowed balance changed");
    }
}
