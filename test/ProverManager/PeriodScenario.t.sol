// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20Currency, ETHCurrency} from "./CurrencyScenario.t.sol";

import {CurrentPeriodIsActiveTest} from "./CurrentPeriodIsActiveTest.t.sol";

import {CurrentPeriodHasPublications} from "./CurrentPeriodHasPublications.t.sol";

import {CurrentPeriodIsOpenTest} from "./CurrentPeriodIsOpenTest.t.sol";
import {CurrentPeriodIsOverTest} from "./CurrentPeriodIsOverTest.t.sol";
import {CurrentPeriodIsVacant} from "./CurrentPeriodIsVacant.t.sol";
import {InitialState} from "./InitialState.t.sol";
import {InitialStateTest} from "./InitialStateTest.t.sol";
import {NextPeriodHasBidTest} from "./NextPeriodHasBidTest.t.sol";
import {PreviousPeriodHasPublications} from "./PreviousPeriodHasPublications.t.sol";
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

        // extend the period time so there could be expired publications
        vm.warp(vm.getBlockTimestamp() + 3 * proverManager.livenessWindow());
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

        // extend the period time so there could be expired publications
        // this also ensures the proving deadline for Period 1 is over
        vm.warp(vm.getBlockTimestamp() + 3 * proverManager.livenessWindow());
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

        // extend the period time so there could be expired publications
        vm.warp(vm.getBlockTimestamp() + 3 * proverManager.livenessWindow());
    }
}

// Instantiations

contract InitialStateTest_ETH is InitialStateTest, CurrentPeriodHasPublications, ETHCurrency {}

contract InitialStateTest_ERC20 is InitialStateTest, CurrentPeriodHasPublications, ERC20Currency {
    function setUp() public virtual override(InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        InitialState.setUp();
    }
}

contract PeriodZeroIsOver_ETH is
    PeriodZeroIsOver,
    CurrentPeriodIsOverTest,
    CurrentPeriodHasPublications,
    ETHCurrency
{
    function setUp() public virtual override(PeriodZeroIsOver, InitialState) {
        PeriodZeroIsOver.setUp();
    }
}

contract PeriodZeroIsOver_ERC20 is
    PeriodZeroIsOver,
    CurrentPeriodIsOverTest,
    CurrentPeriodHasPublications,
    ERC20Currency
{
    function setUp() public virtual override(PeriodZeroIsOver, InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodZeroIsOver.setUp();
    }
}

contract PeriodOneIsActive_ETH is
    PeriodOneIsActive,
    CurrentPeriodIsOpenTest,
    PreviousPeriodHasPublications,
    ETHCurrency
{
    function setUp() public virtual override(PeriodOneIsActive, InitialState) {
        PeriodOneIsActive.setUp();
    }
}

contract PeriodOneIsActive_ERC20 is
    PeriodOneIsActive,
    CurrentPeriodIsOpenTest,
    PreviousPeriodHasPublications,
    ERC20Currency
{
    function setUp() public virtual override(PeriodOneIsActive, InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodOneIsActive.setUp();
    }
}

contract PeriodTwoHasBidder_ETH is
    PeriodTwoHasBidder,
    CurrentPeriodIsActiveTest,
    NextPeriodHasBidTest,
    PreviousPeriodHasPublications,
    ETHCurrency
{
    function setUp() public virtual override(PeriodTwoHasBidder, InitialState) {
        PeriodTwoHasBidder.setUp();
    }
}

contract PeriodTwoHasBidder_ERC20 is
    PeriodTwoHasBidder,
    CurrentPeriodIsActiveTest,
    NextPeriodHasBidTest,
    PreviousPeriodHasPublications,
    ERC20Currency
{
    function setUp() public virtual override(PeriodTwoHasBidder, InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodTwoHasBidder.setUp();
    }
}

contract PeriodTwoIsActive_ETH is
    PeriodTwoIsActive,
    CurrentPeriodIsOpenTest,
    PreviousPeriodHasPublications,
    ETHCurrency
{
    function setUp() public virtual override(PeriodTwoIsActive, InitialState) {
        PeriodTwoIsActive.setUp();
    }
}

contract PeriodTwoIsActive_ERC20 is
    PeriodTwoIsActive,
    CurrentPeriodIsOpenTest,
    PreviousPeriodHasPublications,
    ERC20Currency
{
    function setUp() public virtual override(PeriodTwoIsActive, InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodTwoIsActive.setUp();
    }
}

contract PeriodTwoIsVacant_ETH is
    PeriodTwoIsVacant,
    CurrentPeriodIsVacant,
    PreviousPeriodHasPublications,
    ETHCurrency
{
    function setUp() public virtual override(PeriodTwoIsVacant, InitialState) {
        PeriodTwoIsVacant.setUp();
    }
}

contract PeriodTwoIsVacant_ERC20 is
    PeriodTwoIsVacant,
    CurrentPeriodIsVacant,
    PreviousPeriodHasPublications,
    ERC20Currency
{
    function setUp() public virtual override(PeriodTwoIsVacant, InitialState, ERC20Currency) {
        ERC20Currency.setUp();
        PeriodTwoIsVacant.setUp();
    }
}
