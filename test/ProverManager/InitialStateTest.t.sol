// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20Currency, ETHCurrency} from "./CurrencyScenario.t.sol";
import {InitialState} from "./InitialState.t.sol";
import {InvariantTest} from "./InvariantTest.t.sol";
import {LibProvingPeriod} from "src/libs/LibProvingPeriod.sol";

/// Represents the initial state of the ProverManager contract after deployment.
/// @dev This should be inherited to cover the ETH and ERC20 scenarios.
abstract contract InitialStateTest is InvariantTest {
    function test_DeployerBalanceIsZero() public view {
        assertEq(proverManager.balances(deployer), 0, "Deployer has non-zero balance");
    }

    function test_ProverBalanceIsDepositOverLivenessBond() public view {
        uint256 expectedBalance = initialDeposit - proverManager.livenessBond();
        assertEq(proverManager.balances(initialProver), expectedBalance, "Prover has incorrect balance");
    }

    // Confirm the ProverManager address retrieved the initial deposit
    function test_ProverManagerHasInitialDeposit() public view virtual;

    function test_CurrentPeriodIsZero() public view {
        // The current period does not change until there is a proposal in the new period
        assertEq(proverManager.currentPeriodId(), 0, "Current period is not 0");
    }

    function test_PeriodZeroIsEmptyAndEndsThisBlock() public view {
        LibProvingPeriod.Period memory period = proverManager.getPeriod(0);
        assertEq(period.prover, address(0), "Period 0 prover is not address(0)");
        assertEq(period.stake, 0, "Period 0 stake is not 0");
        assertEq(period.fee, 0, "Period 0 fee is not 0");
        assertEq(period.delayedFeePercentage, 0, "Period 0 delayed fee percentage is not 0");
        assertEq(period.end, vm.getBlockTimestamp(), "Period 0 end is not this block timestamp");
        assertEq(period.deadline, vm.getBlockTimestamp(), "Period 0 deadline is not this block timestamp");
        assertEq(period.pastDeadline, false, "Period 0 has missed deadline");
    }

    function test_PeriodOneIsInitialized() public view {
        LibProvingPeriod.Period memory period = proverManager.getPeriod(1);
        assertEq(period.prover, initialProver, "Period 1 prover is not initialProver");
        assertEq(period.stake, proverManager.livenessBond(), "Period 1 stake is not liveness bond");
        assertEq(period.fee, initialFee, "Period 1 fee is not initialFee");
        assertEq(
            period.delayedFeePercentage,
            proverManager.delayedFeePercentage(),
            "Period 1 delayed fee percentage does not match prover manager config"
        );
        assertEq(period.end, 0, "Period 1 has end timestamp");
        assertEq(period.deadline, 0, "Period 1 has deadline");
        assertEq(period.pastDeadline, false, "Period 0 has missed deadline");
    }
}

contract InitialStateTest_ETH is InitialStateTest, ETHCurrency {
    function test_ProverManagerHasInitialDeposit() public view override {
        assertEq(address(proverManager).balance, initialDeposit, "ProverManager does not have the initial deposit");
    }
}

contract InitialStateTest_ERC20 is InitialStateTest, ERC20Currency {
    function setUp() public virtual override(InitialState, ERC20Currency) {
        ERC20Currency.setUp();
    }

    function test_ProverManagerHasInitialDeposit() public view override {
        assertEq(
            token.balanceOf(address(proverManager)), initialDeposit, "ProverManager does not have the initial deposit"
        );
    }
}
