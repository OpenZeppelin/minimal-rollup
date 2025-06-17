// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {InvariantTest} from "./InvariantTest.t.sol";
import {BalanceAccounting} from "src/protocol/BalanceAccounting.sol";
import {BaseProverManager} from "src/protocol/BaseProverManager.sol";

/// This contract describes behaviours that should be valid in every state
/// It can be inherited by any Test contract to run all tests in that state
abstract contract UniversalTest is InvariantTest {
    function test_Universal_deposit() public {
        uint256 escrowedBefore = _currencyBalance(address(proverManager));
        uint256 balanceBefore = proverManager.balances(proposer);

        _prepareForDeposit(proposer, DEPOSIT_AMOUNT);
        vm.expectEmit(address(proverManager));
        emit BalanceAccounting.Deposit(proposer, DEPOSIT_AMOUNT);
        _executeDeposit(proposer, DEPOSIT_AMOUNT);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));
        uint256 balanceAfter = proverManager.balances(proposer);

        assertEq(escrowedAfter, escrowedBefore + DEPOSIT_AMOUNT, "Value not transferred to ProverManager");
        assertEq(balanceAfter, balanceBefore + DEPOSIT_AMOUNT, "Balance not updated correctly");
    }

    function test_Universal_withdraw() public {
        _prepareForDeposit(proposer, DEPOSIT_AMOUNT);
        _executeDeposit(proposer, DEPOSIT_AMOUNT);

        uint256 escrowedBefore = _currencyBalance(address(proverManager));
        uint256 balanceBefore = proverManager.balances(proposer);

        vm.expectEmit();
        emit BalanceAccounting.Withdrawal(proposer, WITHDRAW_AMOUNT);
        vm.prank(proposer);
        proverManager.withdraw(WITHDRAW_AMOUNT);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));
        uint256 balanceAfter = proverManager.balances(proposer);

        assertEq(escrowedAfter, escrowedBefore - WITHDRAW_AMOUNT, "Value not transferred from ProverManager");
        assertEq(balanceAfter, balanceBefore - WITHDRAW_AMOUNT, "Balance not updated correctly");
    }

    function test_Universal_payPublicationFee_RevertWhenNotCalledByInbox() public {
        vm.expectRevert(BaseProverManager.OnlyInbox.selector);
        proverManager.payPublicationFee(proposer, false);
    }

    function _initializeProposerDeposit() internal {
        _prepareForDeposit(proposer, DEPOSIT_AMOUNT);
        _executeDeposit(proposer, DEPOSIT_AMOUNT);
    }
}
