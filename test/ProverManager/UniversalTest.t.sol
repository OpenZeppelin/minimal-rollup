// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ProverManager} from "../../src/protocol/taiko_alethia/ProverManager.sol";
import {InitialState} from "./InitialState.t.sol";
import {InvariantTest} from "./InvariantTest.t.sol";

/// This contract describes behaviours that should be valid in every state
/// It can be inherited by any Test contract to run all tests in that state
abstract contract UniversalTest is InvariantTest {
    // Addresses used for testing
    address proposer = _randomAddress("proposer");

    // Configuration parameters.
    uint256 constant DEPOSIT_AMOUNT = 2 ether;
    uint256 constant WITHDRAW_AMOUNT = 0.5 ether;

    function setUp() public override virtual {
        super.setUp();
        vm.deal(proposer, 10 ether);
    }

    function test_deposit() public {
        uint256 balanceBefore = proverManager.balances(proposer);

        vm.prank(proposer);
        vm.expectEmit();
        emit ProverManager.Deposit(proposer, DEPOSIT_AMOUNT);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 balanceAfter = proverManager.balances(proposer);
        assertEq(balanceAfter, balanceBefore + DEPOSIT_AMOUNT, "Balance not updated correctly");
    }

    function test_withdraw() public {
        vm.startPrank(proposer);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 balanceBefore = proposer.balance;
        vm.expectEmit();
        emit ProverManager.Withdrawal(proposer, WITHDRAW_AMOUNT);
        proverManager.withdraw(WITHDRAW_AMOUNT);

        assertEq(proverManager.balances(proposer), DEPOSIT_AMOUNT - WITHDRAW_AMOUNT, "Balance not updated correctly");
        // Allow a small tolerance for gas.
        uint256 balanceAfter = proposer.balance;
        assertApproxEqAbs(balanceAfter, balanceBefore + WITHDRAW_AMOUNT, 1e15);
    }

    function test_payPublicationFee_RevertWhen_NotInbox() public {
        vm.expectRevert("Only the Inbox contract can call this function");
        proverManager.payPublicationFee(proposer, false);
    }
}
