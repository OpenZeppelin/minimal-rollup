// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ProverManager} from "../../src/protocol/taiko_alethia/ProverManager.sol";
import {InitialState} from "./InitialState.t.sol";
import {InvariantTest} from "./InvariantTest.t.sol";


/// This contract describes behaviours that should be possible in every state
/// It can be inherited by any Test contract to run all tests in that state
abstract contract UniversalTest is InvariantTest {
    // Addresses used for testing
    address depositor = _randomAddress("depositor");

    // Configuration parameters.
    uint256 constant DEPOSIT_AMOUNT = 2 ether;
    uint256 constant WITHDRAW_AMOUNT = 0.5 ether;

    function setUp() public override {
        super.setUp();
        vm.deal(depositor, 10 ether);
    }

    function test_deposit() public {
        uint256 balanceBefore = proverManager.balances(depositor);

        vm.prank(depositor);
        vm.expectEmit();
        emit ProverManager.Deposit(depositor, DEPOSIT_AMOUNT);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 balanceAfter = proverManager.balances(depositor);
        assertEq(balanceAfter, balanceBefore + DEPOSIT_AMOUNT, "Balance not updated correctly");
    }

    function test_withdraw() public {
        vm.startPrank(depositor);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 balanceBefore = depositor.balance;
        vm.expectEmit();
        emit ProverManager.Withdrawal(depositor, WITHDRAW_AMOUNT);
        proverManager.withdraw(WITHDRAW_AMOUNT);

        assertEq(proverManager.balances(depositor), DEPOSIT_AMOUNT - WITHDRAW_AMOUNT, "Balance not updated correctly");
        // Allow a small tolerance for gas.
        uint256 balanceAfter = depositor.balance;
        assertApproxEqAbs(balanceAfter, balanceBefore + WITHDRAW_AMOUNT, 1e15);
    }
}
