// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20Currency, ETHCurrency} from "./CurrencyScenario.t.sol";
import {InitialState} from "./InitialState.t.sol";

/// Represents the initial state of the ProverManager contract after deployment.
/// @dev This should be inherited to cover the ETH and ERC20 scenarios.
abstract contract InitialStateTest is InitialState {
    function test_DeployerBalanceIsZero() public view {
        assertEq(proverManager.balances(deployer), 0, "Deployer has non-zero balance");
    }

    function test_ProverBalanceIsDepositOverLivenessBond() public view {
        uint256 expectedBalance = initialDeposit - proverManager.livenessBond();
        assertEq(proverManager.balances(initialProver), expectedBalance, "Prover has incorrect balance");
    }

    // Confirm the ProverManager address retrieved the initial deposit
    function test_ProverManagerHasInitialDeposit() public view virtual;
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
