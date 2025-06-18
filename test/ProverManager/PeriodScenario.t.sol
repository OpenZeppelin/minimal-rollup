// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20Currency, ETHCurrency} from "./CurrencyScenario.t.sol";

import {CurrentPeriodIsActiveTest} from "./CurrentPeriodIsActiveTest.t.sol";

import {CurrentPeriodIsOpenTest} from "./CurrentPeriodIsOpenTest.t.sol";
import {CurrentPeriodIsOverTest} from "./CurrentPeriodIsOverTest.t.sol";

import {InitialState} from "./InitialState.t.sol";
import {NextPeriodHasBidTest} from "./NextPeriodHasBidTest.t.sol";
import {LibPercentage} from "src/libs/LibPercentage.sol";

/// Set up various scenarios to cover different period states
/// Instantiate the scenarios by:
/// - using both ETH and ERC20 Prover Managers
/// - selecting the relevant test suites

/// The timestamp is after the end of Period 0 but the new period has not been triggered
abstract contract PeriodZeroIsOver is InitialState {
    function setUp() public virtual override {
        super.setUp();
        vm.warp(vm.getBlockTimestamp() + 1);
    }
}

/// There has been a publication in period 1 to trigger the new period
abstract contract PeriodOneIsActive is PeriodZeroIsOver {
    function setUp() public virtual override {
        super.setUp();

        _deposit(proposer, initialFee);
        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, false);
    }
}

/// Period 1 is active and proverA has bid for the next period
abstract contract PeriodTwoHasBidder is PeriodOneIsActive {
    function setUp() public virtual override {
        super.setUp();

        uint96 offer = LibPercentage.scaleByBPS(initialFee, proverManager.maxBidFraction());
        _deposit(proverA, proverManager.livenessBond());
        vm.prank(address(proverA));
        proverManager.bid(offer);
    }
}

/// Period 2 has started (so period 1 is complete)
abstract contract PeriodTwoIsActive is PeriodTwoHasBidder {
    function setUp() public virtual override {
        super.setUp();
        vm.warp(proverManager.getPeriod(1).end + 1);

        _deposit(proposer, initialFee); // the period 2 fee is less than this
        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, false);
    }
}

/// Period 2 is active but the proving deadline for Period 1 is over
abstract contract PeriodOneDeadlineComplete is PeriodTwoIsActive {
    function setUp() public virtual override {
        super.setUp();
        vm.warp(proverManager.getPeriod(1).deadline + 1);
    }
}

/// Period 2 has started but it has no prover
abstract contract PeriodTwoIsVacant is PeriodOneIsActive {
    function setUp() public virtual override {
        super.setUp();
        vm.prank(initialProver);
        proverManager.exit();

        vm.warp(proverManager.getPeriod(1).end + 1);
        // no deposit necessary because there is no fee in vacant periods
        vm.prank(address(inbox));
        proverManager.payPublicationFee(proposer, false);
    }
}

// Instantiations
contract PeriodZeroIsOver_ETH is PeriodZeroIsOver, CurrentPeriodIsOverTest, ETHCurrency {
    function setUp() public virtual override(PeriodZeroIsOver, InitialState) {
        PeriodZeroIsOver.setUp();
    }
}

contract PeriodZeroIsOver_ERC20 is PeriodZeroIsOver, CurrentPeriodIsOverTest, ERC20Currency {
    function setUp() public virtual override(PeriodZeroIsOver, InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodZeroIsOver.setUp();
    }
}

contract PeriodOneIsActive_ETH is PeriodOneIsActive, CurrentPeriodIsOpenTest, ETHCurrency {
    function setUp() public virtual override(PeriodOneIsActive, InitialState) {
        PeriodOneIsActive.setUp();
    }
}

contract PeriodOneIsActive_ERC20 is PeriodOneIsActive, CurrentPeriodIsOpenTest, ERC20Currency {
    function setUp() public virtual override(PeriodOneIsActive, InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodOneIsActive.setUp();
    }
}

contract PeriodTwoHasBidder_ETH is PeriodTwoHasBidder, CurrentPeriodIsActiveTest, NextPeriodHasBidTest, ETHCurrency {
    function setUp() public virtual override(PeriodTwoHasBidder, InitialState) {
        PeriodTwoHasBidder.setUp();
    }
}

contract PeriodTwoHasBidder_ERC20 is
    PeriodTwoHasBidder,
    CurrentPeriodIsActiveTest,
    NextPeriodHasBidTest,
    ERC20Currency
{
    function setUp() public virtual override(PeriodTwoHasBidder, InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodTwoHasBidder.setUp();
    }
}

contract PeriodTwoIsActive_ETH is PeriodTwoIsActive, CurrentPeriodIsOpenTest, ETHCurrency {
    function setUp() public virtual override(PeriodTwoIsActive, InitialState) {
        PeriodTwoIsActive.setUp();
    }
}

contract PeriodTwoIsActive_ERC20 is PeriodTwoIsActive, CurrentPeriodIsOpenTest, ERC20Currency {
    function setUp() public virtual override(PeriodTwoIsActive, InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodTwoIsActive.setUp();
    }
}

contract PeriodOneDeadlineComplete_ETH is PeriodOneDeadlineComplete, CurrentPeriodIsOpenTest, ETHCurrency {
    function setUp() public virtual override(PeriodOneDeadlineComplete, InitialState) {
        PeriodOneDeadlineComplete.setUp();
    }
}

contract PeriodOneDeadlineComplete_ERC20 is PeriodOneDeadlineComplete, CurrentPeriodIsOpenTest, ERC20Currency {
    function setUp() public virtual override(PeriodOneDeadlineComplete, InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodOneDeadlineComplete.setUp();
    }
}

contract PeriodTwoIsVacant_ETH is PeriodTwoIsVacant, ETHCurrency {
    function setUp() public virtual override(PeriodTwoIsVacant, InitialState) {
        PeriodTwoIsVacant.setUp();
    }
}

contract PeriodTwoIsVacant_ERC20 is PeriodTwoIsVacant, ERC20Currency {
    function setUp() public virtual override(PeriodTwoIsVacant, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodTwoIsVacant.setUp();
    }
}
