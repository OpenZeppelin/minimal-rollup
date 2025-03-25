// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ProverManager} from "../../src/protocol/taiko_alethia/ProverManager.sol";
import {UniversalTest} from "./UniversalTest.t.sol";

/// This contract describes behaviours that should be valid when the current period is active.
// This implies it has no end timestamp or the end timestamp has not been crossed.
// It can be inherited by any Test contract that respects this condition.
abstract contract CurrentPeriodIsActive is UniversalTest {
    function test_payPublicationFee_ActivePeriod() public {
        uint256 currentPeriod = proverManager.currentPeriodId();
        ProverManager.Period memory p = proverManager.getPeriod(currentPeriod);

        // Deposit funds for proposer.
        vm.prank(proposer);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 balanceBefore = proverManager.balances(proposer);
        vm.prank(inbox);
        proverManager.payPublicationFee{value: 0}(proposer, false);

        uint256 balanceAfter = proverManager.balances(proposer);
        assertEq(balanceAfter, balanceBefore - p.fee, "Publication fee not deducted properly");
    }

    function test_payPublicationFee_ActivePeriodSendEth() public {
        uint256 currentPeriod = proverManager.currentPeriodId();
        ProverManager.Period memory p = proverManager.getPeriod(currentPeriod);

        uint256 balanceBefore = proverManager.balances(proposer);
        vm.prank(inbox);
        vm.expectEmit();
        emit ProverManager.Deposit(proposer, DEPOSIT_AMOUNT);
        proverManager.payPublicationFee{value: DEPOSIT_AMOUNT}(proposer, false);

        uint256 balanceAfter = proverManager.balances(proposer);
        assertEq(balanceAfter, balanceBefore + DEPOSIT_AMOUNT - p.fee, "Publication fee not deducted properly");
    }
}
