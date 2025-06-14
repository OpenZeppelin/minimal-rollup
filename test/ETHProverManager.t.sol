// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {BaseProverManager} from "../src/protocol/BaseProverManager.sol";
import {ETHProverManager} from "../src/protocol/ETHProverManager.sol";
import {IProposerFees} from "../src/protocol/IProposerFees.sol";

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";

import {IInbox} from "src/protocol/IInbox.sol";
import {MockInbox} from "test/mocks/MockInbox.sol";

import {MockCheckpointTracker} from "test/mocks/MockCheckpointTracker.sol";
import {NullVerifier} from "test/mocks/NullVerifier.sol";

import {BaseProverManagerTest} from "./BaseProverManager.t.sol";

import {
    DELAYED_FEE_PERCENTAGE,
    EVICTOR_INCENTIVE_FRACTION,
    EXIT_DELAY,
    INITIAL_FEE,
    INITIAL_PERIOD,
    LIVENESS_BOND,
    LIVENESS_WINDOW,
    MAX_BID_FRACTION,
    PROVING_WINDOW,
    REWARD_FRACTION,
    SUCCESSION_DELAY
} from "./BaseProverManager.t.sol";
import {BalanceAccounting} from "src/protocol/BalanceAccounting.sol";

contract ETHProverManagerMock is ETHProverManager {
    constructor(address _inbox, address _checkpointTracker, address _initialProver, uint96 _initialFee)
        payable
        ETHProverManager(_inbox, _checkpointTracker, _initialProver, _initialFee)
    {}

    function _maxBidFraction() internal view virtual override returns (uint16) {
        return MAX_BID_FRACTION;
    }

    function _livenessWindow() internal view virtual override returns (uint40) {
        return LIVENESS_WINDOW;
    }

    function _successionDelay() internal view virtual override returns (uint40) {
        return SUCCESSION_DELAY;
    }

    function _exitDelay() internal view virtual override returns (uint40) {
        return EXIT_DELAY;
    }

    function _provingWindow() internal view virtual override returns (uint40) {
        return PROVING_WINDOW;
    }

    function _livenessBond() internal view virtual override returns (uint96) {
        return LIVENESS_BOND;
    }

    function _evictorIncentiveFraction() internal view virtual override returns (uint16) {
        return EVICTOR_INCENTIVE_FRACTION;
    }

    function _rewardFraction() internal view virtual override returns (uint16) {
        return REWARD_FRACTION;
    }

    function _delayedFeePercentage() internal view virtual override returns (uint16) {
        return DELAYED_FEE_PERCENTAGE;
    }
}

contract ETHProverManagerTest is BaseProverManagerTest {
    // Holds a reference to `proverManager` but with the type ETHProverManager to be
    // able to call functions that are specific to the ETHProverManager(i.e. `deposit`)
    ETHProverManager ethProverManager;

    function setUp() public override {
        super.setUp();
        proverManager = new ETHProverManagerMock{value: LIVENESS_BOND}(
            address(inbox), address(checkpointTracker), initialProver, INITIAL_FEE
        );
        ethProverManager = ETHProverManager(payable(address(proverManager)));

        // Fund the initial prover so the constructor can receive the required livenessBond.
        vm.deal(initialProver, 10 ether);

        // Fund test users.
        vm.deal(prover1, 10 ether);
        vm.deal(prover2, 10 ether);
        vm.deal(evictor, 10 ether);
        vm.deal(proposer, 10 ether);

        // Fund the Inbox contract.
        vm.deal(address(inbox), 10 ether);

        // Deposit enough as a proposer to pay for publications
        vm.prank(proposer);
        ethProverManager.deposit{value: INITIAL_FEE * 10}();

        // Create a publication to trigger the new period
        vm.warp(vm.getBlockTimestamp() + 1);
        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, false);
    }

    function test_setUp_EthBalance() public view {
        // Test that the contract holds the correct amount of ETH after setup
        uint256 expectedBalance = LIVENESS_BOND + (INITIAL_FEE * 10); // Initial liveness bond + proposer deposit
        uint256 actualBalance = address(proverManager).balance;

        assertEq(actualBalance, expectedBalance, "Contract does not hold the correct ETH balance");
    }

    function test_deposit() public {
        vm.prank(prover1);
        vm.expectEmit();
        emit BalanceAccounting.Deposit(prover1, DEPOSIT_AMOUNT);
        ethProverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 bal = proverManager.balances(prover1);
        assertEq(bal, DEPOSIT_AMOUNT, "Deposit did not update balance correctly");
    }

    function test_withdraw() public {
        uint256 withdrawAmount = 0.5 ether;
        _deposit(prover1, DEPOSIT_AMOUNT);

        // Withdraw 0.5 ether.
        uint256 balanceBefore = prover1.balance;
        vm.prank(prover1);
        vm.expectEmit();
        emit BalanceAccounting.Withdrawal(prover1, withdrawAmount);
        proverManager.withdraw(withdrawAmount);
        uint256 balanceAfter = prover1.balance;

        assertEq(
            proverManager.balances(prover1),
            DEPOSIT_AMOUNT - withdrawAmount,
            "Withdrawal did not update balance correctly"
        );
        // Allow a small tolerance for gas.
        assertApproxEqAbs(balanceAfter, balanceBefore + withdrawAmount, 1e15);
    }

    function _deposit(address user, uint256 amount) internal override {
        vm.prank(user);
        ethProverManager.deposit{value: amount}();
    }
}
