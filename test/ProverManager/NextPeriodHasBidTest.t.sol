// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UniversalTest} from "./UniversalTest.t.sol";

import {LibPercentage} from "src/libs/LibPercentage.sol";
import {LibProvingPeriod} from "src/libs/LibProvingPeriod.sol";
import {BaseProverManager} from "src/protocol/BaseProverManager.sol";
import {IProverManager} from "src/protocol/IProverManager.sol";

/// Represents states where there is an existing bid for the next period
abstract contract NextPeriodHasBidTest is UniversalTest {
    // This is a sanity check to ensure we're in the expected state
    function test_NextPeriodHasBid_confirmPreconditions() public view {
        (address currentBidder,,) = _getCurrentBid();
        assertNotEq(currentBidder, address(0), "No current bidder");
        // we will use proverB as a competing prover
        assertNotEq(currentBidder, proverB, "Invalid test configuration");
    }

    function test_NextPeriodHasBid_bid_shouldRevertIfNewOfferMatchesCurrentOffer() public {
        (, uint96 currentBid,) = _getCurrentBid();
        _deposit(proverB, currentBid);
        vm.prank(proverB);
        vm.expectRevert(BaseProverManager.OfferedFeeTooHigh.selector);
        proverManager.bid(currentBid);
    }

    function test_NextPeriodHasBid_bid_shouldRevertIfNewOfferInsufficientlyUnderbidCurrentOffer() public {
        (, uint96 currentBid,) = _getCurrentBid();
        if (currentBid == 0) {
            // ignore this test if the bid is already zero
        }
        _deposit(proverB, currentBid);
        vm.prank(proverB);
        vm.expectRevert(BaseProverManager.OfferedFeeTooHigh.selector);
        proverManager.bid(currentBid - 1);
    }

    function test_NextPeriodHasBid_bid_shouldNotAffectCurrentPeriod() public {
        (,, uint96 offer) = _getCurrentBid();
        _deposit(proverB, proverManager.livenessBond());

        uint256 currentPeriodId = proverManager.currentPeriodId();
        LibProvingPeriod.Period memory currentPeriodBefore = proverManager.getPeriod(currentPeriodId);

        vm.prank(proverB);
        proverManager.bid(offer);

        assertEq(currentPeriodId, proverManager.currentPeriodId(), "Current period ID changed");
        LibProvingPeriod.Period memory currentPeriodAfter = proverManager.getPeriod(currentPeriodId);

        assertEq(currentPeriodBefore.prover, currentPeriodAfter.prover, "Current prover changed");
        assertEq(currentPeriodBefore.stake, currentPeriodAfter.stake, "Current stake changed");
        assertEq(currentPeriodBefore.fee, currentPeriodAfter.fee, "Current fee changed");
        assertEq(
            currentPeriodBefore.delayedFeePercentage,
            currentPeriodAfter.delayedFeePercentage,
            "Current delayed fee changed"
        );
        assertEq(currentPeriodBefore.end, currentPeriodAfter.end, "Current end timestamp changed");
        assertEq(currentPeriodBefore.deadline, currentPeriodAfter.deadline, "Current deadline changed");
        assertEq(
            currentPeriodBefore.pastDeadline, currentPeriodAfter.pastDeadline, "Current past deadline flag changed"
        );
    }

    function test_NextPeriodHasBid_bid_shouldRefundLosingBidderStake() public {
        (address losingBidder,, uint96 offer) = _getCurrentBid();
        _deposit(proverB, proverManager.livenessBond());

        uint256 escrowedBefore = _currencyBalance(address(proverManager));
        uint256 balanceBefore = proverManager.balances(losingBidder);

        vm.prank(proverB);
        proverManager.bid(offer);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));
        uint256 balanceAfter = proverManager.balances(losingBidder);

        assertEq(escrowedAfter, escrowedBefore, "Value held by ProverManager changed");
        // Note: this assumes the liveness bond has not changed (it is a constant in our current implementation)
        assertEq(balanceAfter, balanceBefore + proverManager.livenessBond(), "Balance not updated correctly");
    }

    function test_NextPeriodHasBid_bid_shouldDeductLivenessBond() public {
        (,, uint96 offer) = _getCurrentBid();
        _deposit(proverB, proverManager.livenessBond());

        uint256 escrowedBefore = _currencyBalance(address(proverManager));
        uint256 balanceBefore = proverManager.balances(proverB);

        vm.prank(proverB);
        proverManager.bid(offer);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));
        uint256 balanceAfter = proverManager.balances(proverB);

        assertEq(escrowedAfter, escrowedBefore, "Value held by ProverManager changed");
        assertEq(balanceAfter, balanceBefore - proverManager.livenessBond(), "Balance not updated correctly");
    }

    function test_NextPeriodHasBid_bid_shouldUpdateNextPeriodWithNewBid() public {
        (,, uint96 offer) = _getCurrentBid();
        _deposit(proverB, proverManager.livenessBond());

        vm.prank(proverB);
        proverManager.bid(offer);

        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId() + 1);

        assertEq(period.prover, proverB, "Prover was not set to new bidder");
        assertEq(period.stake, proverManager.livenessBond(), "Stake was set incorrectly");
        assertEq(period.fee, offer, "Fee was set incorrectly");
        assertEq(period.delayedFeePercentage, proverManager.delayedFeePercentage(), "Delayed fee was set incorrectly");
        assertEq(period.end, 0, "New period has end timestamp");
        assertEq(period.deadline, 0, "New period has deadline");
        assertEq(period.pastDeadline, false, "Period has missed deadline");
    }

    function test_NextPeriodHasBid_bid_shouldEmitEvent() public {
        (,, uint96 offer) = _getCurrentBid();
        uint96 bond = proverManager.livenessBond();
        _deposit(proverB, bond);
        uint256 currentPeriodId = proverManager.currentPeriodId();

        vm.prank(proverB);
        vm.expectEmit();
        emit IProverManager.ProverOffer(proverB, currentPeriodId + 1, offer, bond);
        proverManager.bid(offer);
    }

    function test_NextPeriodHasBid_bid_shouldAllowCurrentBidderToLowerOwnBid() public {
        (address currentBidder,, uint96 offer) = _getCurrentBid();
        // no additional deposit needed because the previous bond is refunded before the new one is deducted
        // this assumes the liveness bond has not changed (it is a constant in our current implementation)
        // withdraw any funds to ensure this path is tested
        uint256 balance = proverManager.balances(currentBidder);
        vm.prank(currentBidder);
        proverManager.withdraw(balance);

        vm.prank(currentBidder);
        proverManager.bid(offer);

        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId() + 1);
        assertEq(period.prover, currentBidder, "Bidder has changed");
        assertEq(period.fee, offer, "Bid was set incorrectly");
    }

    function test_NextPeriodHasBid_bid_shouldAllowZeroBid() public {
        (, uint96 currentBid,) = _getCurrentBid();
        if (currentBid == 0) {
            // ignore this test if the bid is already zero
            return;
        }

        _deposit(proverB, proverManager.livenessBond());
        vm.prank(proverB);
        proverManager.bid(0);

        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId() + 1);
        assertEq(period.prover, proverB, "Bidder was set incorrectly");
        assertEq(period.fee, 0, "Bid was not set to zero");
    }

    function test_NextPeriodHasBid_bid_shouldRevertIfBidderHasInsufficientBalance() public {
        // Sanity check. This precondition should occur automatically because there is no _deposit call
        assertLe(proverManager.balances(proverB), proverManager.livenessBond(), "Invalid test configuration");

        (,, uint96 offer) = _getCurrentBid();
        vm.prank(proverB);
        vm.expectRevert();
        proverManager.bid(offer);
    }

    function _getCurrentBid() private view returns (address bidder, uint96 bid, uint96 validOffer) {
        LibProvingPeriod.Period memory period = proverManager.getPeriod(proverManager.currentPeriodId() + 1);
        uint96 offer = LibPercentage.scaleByBPS(period.fee, proverManager.maxBidFraction());
        return (period.prover, period.fee, offer);
    }
}
