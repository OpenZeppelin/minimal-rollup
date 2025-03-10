// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ProverManager} from "../src/protocol/taiko_alethia/ProverManager.sol";

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";
import {IPublicationFeed} from "src/protocol/IPublicationFeed.sol";
import {PublicationFeed} from "src/protocol/PublicationFeed.sol";

import {MockCheckpointTracker} from "test/mocks/MockCheckpointTracker.sol";

contract ProverManagerTest is Test {
    ProverManager proverManager;
    MockCheckpointTracker checkpointTracker;
    PublicationFeed publicationFeed;
    uint256 constant DEPOSIT_AMOUNT = 2 ether;

    // Addresses used for testing.
    address inbox = address(0x100);
    address initialProver = address(0x101);
    address prover1 = address(0x200);
    address prover2 = address(0x201);
    address proposer = address(0x202);
    address evictor = address(0x203);

    // Configuration parameters.
    uint256 constant MIN_UNDERCUT_PERCENTAGE = 500; // 5%
    uint256 constant LIVENESS_WINDOW = 60; // 60 seconds
    uint256 constant SUCCESSION_DELAY = 10;
    uint256 constant EXIT_DELAY = 10;
    uint256 constant DELAYED_FEE_MULTIPLIER = 2;
    uint256 constant PROVING_DEADLINE = 30;
    uint256 constant LIVENESS_BOND = 1 ether;
    uint256 constant EVICTOR_INCENTIVE_PERCENTAGE = 500; // 5%
    uint256 constant BURNED_STAKE_PERCENTAGE = 1000; // 10%
    uint256 constant INITIAL_FEE = 0.1 ether;

    function setUp() public {
        checkpointTracker = new MockCheckpointTracker();
        publicationFeed = new PublicationFeed();
        // createSampleFeed();

        // Fund the initial prover so the constructor can receive the required livenessBond.
        vm.deal(initialProver, 10 ether);

        // Create the config struct for the constructor
        ProverManager.ProverManagerConfig memory config = ProverManager.ProverManagerConfig({
            minUndercutPercentage: MIN_UNDERCUT_PERCENTAGE,
            livenessWindow: LIVENESS_WINDOW,
            succesionDelay: SUCCESSION_DELAY,
            exitDelay: EXIT_DELAY,
            delayedFeeMultiplier: DELAYED_FEE_MULTIPLIER,
            provingDeadline: PROVING_DEADLINE,
            livenessBond: LIVENESS_BOND,
            evictorIncentivePercentage: EVICTOR_INCENTIVE_PERCENTAGE,
            burnedStakePercentage: BURNED_STAKE_PERCENTAGE
        });

        // Deploy ProverManager with constructor funds.
        proverManager = new ProverManager{value: LIVENESS_BOND}(
            inbox, address(checkpointTracker), address(publicationFeed), initialProver, INITIAL_FEE, config
        );

        // Fund test users.
        vm.deal(prover1, 10 ether);
        vm.deal(prover2, 10 ether);
        vm.deal(evictor, 10 ether);
        vm.deal(proposer, 10 ether);

        // Fund the Inbox contract.
        vm.deal(inbox, 10 ether);
    }

    /// --------------------------------------------------------------------------
    /// Deposit and Withdraw
    /// --------------------------------------------------------------------------
    function test_deposit() public {
        vm.prank(prover1);
        vm.expectEmit();
        emit ProverManager.Deposit(prover1, DEPOSIT_AMOUNT);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 bal = proverManager.balances(prover1);
        assertEq(bal, DEPOSIT_AMOUNT, "Deposit did not update balance correctly");
    }

    function test_withdraw() public {
        uint256 withdrawAmount = 0.5 ether;
        vm.startPrank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        // Withdraw 0.5 ether.
        uint256 balanceBefore = prover1.balance;
        vm.expectEmit();
        emit ProverManager.Withdrawal(prover1, withdrawAmount);
        proverManager.withdraw(withdrawAmount);
        uint256 balanceAfter = prover1.balance;

        assertEq(
            proverManager.balances(prover1),
            DEPOSIT_AMOUNT - withdrawAmount,
            "Withdrawal did not update balance correctly"
        );
        // Allow a small tolerance for gas.
        assertApproxEqAbs(balanceAfter, balanceBefore + 0.5 ether, 1e15);
    }

    /// --------------------------------------------------------------------------
    /// payPublicationFee()
    /// --------------------------------------------------------------------------
    function test_payPublicationFee_RevertWhen_NotInbox() public {
        vm.expectRevert("Only the Inbox contract can call this function");
        proverManager.payPublicationFee(prover1, false);
    }

    function test_payPublicationFee_SamePeriod() public {
        // Deposit funds for proposer.
        vm.prank(proposer);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 balanceBefore = proverManager.balances(proposer);
        // Call payPublicationFee from the inbox.
        vm.prank(inbox);
        proverManager.payPublicationFee{value: 0}(proposer, false);

        uint256 balanceAfter = proverManager.balances(proposer);
        // The fee deducted should be INITIAL_FEE.
        assertEq(balanceAfter, balanceBefore - INITIAL_FEE, "Publication fee not deducted properly");
    }

    function test_payPublicationFee_AllowsToSendEth() public {
        // Call payPublicationFee from the inbox.
        vm.prank(inbox);
        vm.expectEmit();
        emit ProverManager.Deposit(proposer, DEPOSIT_AMOUNT);
        proverManager.payPublicationFee{value: DEPOSIT_AMOUNT}(proposer, false);

        uint256 balanceAfter = proverManager.balances(proposer);
        // The fee deducted should be INITIAL_FEE.
        assertEq(balanceAfter, DEPOSIT_AMOUNT - INITIAL_FEE, "Publication fee not deducted properly");
    }

    function test_payPublicationFee_AdvacesPeriod() public {
        // Deposit funds for proposer.
        vm.prank(proposer);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        // Exit as a prover.
        vm.prank(initialProver);
        proverManager.exit();

        // Warp to a time after the period has ended.
        vm.warp(block.timestamp + EXIT_DELAY + 1);

        // Call payPublicationFee from the inbox and check that the period has been advanced.
        vm.prank(inbox);
        vm.expectEmit();
        emit ProverManager.NewPeriod(1);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
    }

    /// --------------------------------------------------------------------------
    /// bid()
    /// --------------------------------------------------------------------------
    function test_bid_ActivePeriod() public {
        // prover1 deposits sufficient funds
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        // Calculate the minimum required undercut
        uint256 minUndercut = (INITIAL_FEE * MIN_UNDERCUT_PERCENTAGE) / 10000;
        uint256 maxAllowedFee = INITIAL_FEE - minUndercut;

        vm.prank(prover1);
        vm.expectEmit();
        emit ProverManager.ProverOffer(prover1, 1, maxAllowedFee, LIVENESS_BOND);
        proverManager.bid(maxAllowedFee);

        // Check that period 1 has been created
        ProverManager.Period memory period = proverManager.getPeriod(1);

        assertEq(period.prover, prover1, "Bid not recorded for new period");
        assertEq(period.fee, maxAllowedFee, "Offered fee not set correctly");
        assertEq(period.stake, LIVENESS_BOND, "Liveness bond not locked");
        assertEq(period.accumulatedFees, 0, "Accumulated fees should be zero");
        assertEq(period.end, 0, "Period end should be zero until active");
        assertEq(period.deadline, 0, "Deadline should be zero until active");

        // Check that prover1's balance was reduced by the liveness bond
        uint256 prover1Bal = proverManager.balances(prover1);
        assertEq(prover1Bal, DEPOSIT_AMOUNT - LIVENESS_BOND, "User balance not deducted correctly");
    }

    function test_bid_RevertWhen_InsufficientBalance() public {
        // Attempt to bid without sufficient balance for liveness bond
        vm.prank(prover2);
        vm.expectRevert("Insufficient balance for liveness bond");
        proverManager.bid(0.05 ether);
    }

    function test_bid_RevertWhen_FeeNotLowEnough() public {
        // prover1 deposits sufficient funds
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        // Calculate a fee that's not low enough (only 0.5% lower)
        uint256 minUndercut = (INITIAL_FEE * MIN_UNDERCUT_PERCENTAGE) / 10000;
        uint256 insufficientlyReducedFee = INITIAL_FEE - minUndercut + 1;

        vm.prank(prover1);
        vm.expectRevert("Offered fee not low enough");
        proverManager.bid(insufficientlyReducedFee);
    }

    function test_bid_ExistingNextPeriod() public {
        // First, have prover1 make a successful bid
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 firstBidFee = INITIAL_FEE - (INITIAL_FEE * MIN_UNDERCUT_PERCENTAGE) / 10000;
        vm.prank(prover1);
        proverManager.bid(firstBidFee);

        // Now have prover2 outbid prover1
        vm.prank(prover2);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        // Calculate required fee for second bid
        uint256 secondBidFee = firstBidFee - (firstBidFee * MIN_UNDERCUT_PERCENTAGE) / 10000;

        vm.prank(prover2);
        vm.expectEmit();
        emit ProverManager.ProverOffer(prover2, 1, secondBidFee, LIVENESS_BOND);
        proverManager.bid(secondBidFee);

        // Check that period 1 now has prover2 as the prover
        ProverManager.Period memory period = proverManager.getPeriod(1);
        assertEq(period.prover, prover2, "Prover2 should now be the next prover");
        assertEq(period.fee, secondBidFee, "Fee should be updated to prover2's bid");

        // Check that prover1 got their liveness bond back
        uint256 prover1Bal = proverManager.balances(prover1);
        assertEq(prover1Bal, DEPOSIT_AMOUNT, "Prover1 should have their liveness bond refunded");

        // Check that prover2's balance was reduced
        uint256 prover2Bal = proverManager.balances(prover2);
        assertEq(prover2Bal, DEPOSIT_AMOUNT - LIVENESS_BOND, "Prover2's balance should be reduced by liveness bond");
    }

    function test_bid_ActivatesSuccessionDelay() public {
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        // Record the current timestamp
        uint256 timestampBefore = block.timestamp;

        // Make a bid that will outbid the current prover
        uint256 bidFee = INITIAL_FEE - (INITIAL_FEE * MIN_UNDERCUT_PERCENTAGE) / 10000;
        vm.prank(prover1);
        proverManager.bid(bidFee);

        // Check that period 0 now has an end time set
        ProverManager.Period memory period = proverManager.getPeriod(0);
        assertEq(
            period.end,
            timestampBefore + SUCCESSION_DELAY,
            "Period end should be set to current time + succession delay"
        );
        assertEq(
            period.deadline, timestampBefore + SUCCESSION_DELAY + PROVING_DEADLINE, "Deadline should be set correctly"
        );
    }

    function test_bid_RevertWhen_NotEnoughUndercutOnNextPeriod() public {
        // First, have prover1 make a successful bid
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 firstBidFee = INITIAL_FEE - (INITIAL_FEE * MIN_UNDERCUT_PERCENTAGE) / 10000;
        vm.prank(prover1);
        proverManager.bid(firstBidFee);

        // Now have prover2 try to bid with insufficient undercut
        vm.prank(prover2);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 minUndercut = (firstBidFee * MIN_UNDERCUT_PERCENTAGE) / 10000;
        uint256 insufficientlyReducedFee = firstBidFee - minUndercut + 1;

        vm.prank(prover2);
        vm.expectRevert("Offered fee not low enough");
        proverManager.bid(insufficientlyReducedFee);
    }

    /// --------------------------------------------------------------------------
    /// evictProver()
    /// --------------------------------------------------------------------------
    function test_evictProver() public {
        IPublicationFeed.PublicationHeader memory header = _insertPublication();
        uint256 pubId = 1;

        // Capture current period stake before eviction
        ProverManager.Period memory periodBefore = proverManager.getPeriod(0);
        uint256 stakeBefore = periodBefore.stake;

        // Evict the prover
        vm.warp(block.timestamp + LIVENESS_WINDOW + 1);
        vm.prank(evictor);
        vm.expectEmit();
        emit ProverManager.ProverEvicted(
            initialProver,
            evictor,
            block.timestamp + EXIT_DELAY,
            stakeBefore - (stakeBefore * EVICTOR_INCENTIVE_PERCENTAGE) / 10000
        );
        proverManager.evictProver(pubId, header);

        // Verify period 0 is marked as evicted and its stake reduced
        ProverManager.Period memory periodAfter = proverManager.getPeriod(0);
        assertEq(periodAfter.deadline, block.timestamp + EXIT_DELAY, "Prover should be evicted");

        // Calculate expected incentive for the evictor
        uint256 incentive = (stakeBefore * EVICTOR_INCENTIVE_PERCENTAGE) / 10000;
        assertEq(periodAfter.stake, stakeBefore - incentive, "Stake not reduced correctly");
        assertEq(periodAfter.end, block.timestamp + EXIT_DELAY, "Period end not set correctly");

        // Verify that the evictor's balance increased by the incentive
        uint256 evictorBal = proverManager.balances(evictor);
        assertEq(evictorBal, incentive, "Evictor did not receive correct incentive");
    }

    function test_evictProver_RevertWhen_PublicationNotOldEnough() public {
        IPublicationFeed.PublicationHeader memory header = _insertPublication();
        uint256 pubId = 1;

        // Evict the prover with a publication that is not old enough
        vm.warp(block.timestamp + LIVENESS_WINDOW);
        vm.prank(evictor);
        vm.expectRevert("Publication is not old enough");
        proverManager.evictProver(pubId, header);
    }

    function test_evictProver_RevertWhen_InvalidPublicationHeader() public {
        uint256 initialTimestamp = block.timestamp;
        vm.warp(initialTimestamp + LIVENESS_WINDOW + 1);

        IPublicationFeed.PublicationHeader memory header = _insertPublication();
        uint256 pubId = 1;
        // Tamper with the header
        header.timestamp = initialTimestamp;

        // Evict the prover with an invalid publication header
        vm.prank(evictor);
        vm.expectRevert("Publication hash does not match");
        proverManager.evictProver(pubId, header);
    }

    /// --------------------------------------------------------------------------
    /// exit()
    /// --------------------------------------------------------------------------
    function test_exit() public {
        // initialProver is the prover for period 0
        vm.prank(initialProver);
        vm.expectEmit();
        emit ProverManager.ProverExited(
            initialProver, block.timestamp + EXIT_DELAY, block.timestamp + EXIT_DELAY + PROVING_DEADLINE
        );
        proverManager.exit();

        // Check that period 0 now has an end time and deadline set
        ProverManager.Period memory period = proverManager.getPeriod(0);
        assertEq(period.end, block.timestamp + EXIT_DELAY, "Exit did not set period end correctly");
        assertEq(period.deadline, block.timestamp + EXIT_DELAY + PROVING_DEADLINE, "Proving deadline not set correctly");
    }

    function test_exit_RevertWhen_NotCurrentProver() public {
        // Attempt to exit as a non-prover
        vm.prank(prover1);
        vm.expectRevert("Not current prover");
        proverManager.exit();
    }

    function test_exit_RevertWhen_AlreadyExited() public {
        // First exit
        vm.prank(initialProver);
        proverManager.exit();

        // Try to exit again
        vm.prank(initialProver);
        vm.expectRevert("Prover already exited");
        proverManager.exit();
    }

    /// --------------------------------------------------------------------------
    /// proveOpenPeriod()
    /// --------------------------------------------------------------------------
    function test_proveOpenPeriod_CompletesPeriod() public {
        // Setup: Create publications and pay for the fees
        uint256 provingPeriodId = 0;
        IPublicationFeed.PublicationHeader memory startHeader = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader = _insertPublication();
        vm.startPrank(inbox);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
        vm.stopPrank();

        // Exit as the initial prover to set period end
        vm.prank(initialProver);
        proverManager.exit();

        // Warp to after exit delay to advance to next period
        vm.warp(block.timestamp + EXIT_DELAY + 1);

        // Have prover1 bid for next period
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();
        uint256 bidFee = INITIAL_FEE - (INITIAL_FEE * MIN_UNDERCUT_PERCENTAGE) / 10000;
        vm.prank(prover1);
        proverManager.bid(bidFee);

        // Advance to period 1
        vm.prank(inbox);
        proverManager.payPublicationFee{value: bidFee}(proposer, false);

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        // Create a next publication header that's after the period end
        vm.warp(block.timestamp + EXIT_DELAY + 1);
        IPublicationFeed.PublicationHeader memory nextHeader = _insertPublication();
        bytes memory nextHeaderBytes = abi.encode(nextHeader);

        // // Prove the period
        uint256 proverBalanceBefore = proverManager.balances(initialProver);

        proverManager.proveOpenPeriod(
            startCheckpoint,
            endCheckpoint,
            startHeader,
            endHeader,
            nextHeaderBytes,
            "0x", // any proof
            provingPeriodId
        );

        uint256 proverBalanceAfter = proverManager.balances(initialProver);
        assertEq(
            proverBalanceAfter,
            proverBalanceBefore + INITIAL_FEE * 2 + LIVENESS_BOND,
            "Prover should receive stake and fees"
        );
    }

    function test_proveOpenPeriod_InsidePeriod() public {
        // Setup: Create publications and pay for the fees
        uint256 provingPeriodId = 0;
        IPublicationFeed.PublicationHeader memory startHeader = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader = _insertPublication();
        vm.startPrank(inbox);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
        vm.stopPrank();

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        // // Prove the period
        uint256 proverBalanceBefore = proverManager.balances(initialProver);

        proverManager.proveOpenPeriod(
            startCheckpoint,
            endCheckpoint,
            startHeader,
            endHeader,
            "", // empty next publication header
            "0x", // any proof
            provingPeriodId
        );

        uint256 proverBalanceAfter = proverManager.balances(initialProver);
        ProverManager.Period memory periodAfter = proverManager.getPeriod(provingPeriodId);
        assertEq(
            periodAfter.accumulatedFees, INITIAL_FEE * 2, "Accumulated fees should be the sum of the two publications"
        );
        assertEq(periodAfter.stake, LIVENESS_BOND, "Stake should be the liveness bond");
        assertEq(proverBalanceAfter, proverBalanceBefore, "Prover should not receive any funds yet");
    }

    function test_proveOpenPeriod_RevertWhen_DeadlinePassed() public {
        // Setup: Create publications and advance to period 1
        IPublicationFeed.PublicationHeader memory startHeader = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader = _insertPublication();

        // Exit as the initial prover to set period end
        vm.prank(initialProver);
        proverManager.exit();

        // Have prover1 bid for next period
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();
        uint256 bidFee = INITIAL_FEE - (INITIAL_FEE * MIN_UNDERCUT_PERCENTAGE) / 10000;
        vm.prank(prover1);
        proverManager.bid(bidFee);

        // Advance to period 1
        vm.warp(block.timestamp + EXIT_DELAY + 1);
        vm.prank(inbox);
        proverManager.payPublicationFee{value: bidFee}(proposer, false);

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        // Warp past the deadline
        vm.warp(block.timestamp + PROVING_DEADLINE + 1);

        // Attempt to prove the period after deadline
        vm.expectRevert("Deadline has passed");
        proverManager.proveOpenPeriod(startCheckpoint, endCheckpoint, startHeader, endHeader, "", "0x", 0);
    }

    /// --------------------------------------------------------------------------
    /// proveClosedPeriod()
    /// --------------------------------------------------------------------------
    function test_proveClosedPeriod_AfterEviction() public {
        // Setup: Create publications and pay for the fees
        IPublicationFeed.PublicationHeader memory startHeader = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader = _insertPublication();
        vm.startPrank(inbox);
        // We pay 4 times for the fees(simulating there were two previous publications that were proven by the initial
        // prover)
        uint256 numPubs = 4;
        for (uint256 i; i < numPubs; ++i) {
            proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
        }
        vm.stopPrank();

        // Evict the prover
        vm.warp(block.timestamp + LIVENESS_WINDOW + 1);
        vm.prank(evictor);
        proverManager.evictProver(startHeader.id, startHeader);

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        // Create a next publication header that's after the period end
        vm.warp(block.timestamp + EXIT_DELAY + 1);
        IPublicationFeed.PublicationHeader memory nextHeader = _insertPublication();

        // Create an array of publication headers to prove
        IPublicationFeed.PublicationHeader[] memory pubHeaders = new IPublicationFeed.PublicationHeader[](2);
        pubHeaders[0] = startHeader;
        pubHeaders[1] = endHeader;

        // Capture balances before proving
        uint256 prover1BalanceBefore = proverManager.balances(prover1);
        uint256 initialProverBalanceBefore = proverManager.balances(initialProver);

        // Have prover1 prove the closed period
        vm.prank(prover1);
        proverManager.proveClosedPeriod(
            startCheckpoint,
            endCheckpoint,
            pubHeaders,
            nextHeader,
            "0x", // any proof
            0
        );

        // Check that the initial prover received some fees (for work already done)
        uint256 initialProverBalanceAfter = proverManager.balances(initialProver);
        assertEq(
            initialProverBalanceAfter,
            initialProverBalanceBefore + INITIAL_FEE * 2,
            "Initial prover should receive some fees"
        );

        // Check that prover1 received the fees for the publications they proved plus part of the liveness bond
        uint256 prover1BalanceAfter = proverManager.balances(prover1);
        uint256 expectedFees = INITIAL_FEE * 2; // Two publications
        uint256 evictorIncentive = (LIVENESS_BOND * EVICTOR_INCENTIVE_PERCENTAGE) / 10000;
        uint256 burnedStake = ((LIVENESS_BOND - evictorIncentive) * BURNED_STAKE_PERCENTAGE) / 10000;
        uint256 expectedLivenessBondReward =
            LIVENESS_BOND - burnedStake - (LIVENESS_BOND * EVICTOR_INCENTIVE_PERCENTAGE) / 10000;

        assertEq(
            prover1BalanceAfter,
            prover1BalanceBefore + expectedFees + expectedLivenessBondReward,
            "Prover1 should receive correct amount of fees and liveness bond"
        );
    }

    function test_proveClosedPeriod_AfterDeadlinePassed() public {
        // Setup: Create publications and pay for the fees
        IPublicationFeed.PublicationHeader memory startHeader = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader = _insertPublication();
        vm.startPrank(inbox);
        // We pay 4 times for the fees(simulating there were two previous publications that were proven by the initial
        // prover)
        uint256 numPubs = 4;
        for (uint256 i; i < numPubs; ++i) {
            proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
        }
        vm.stopPrank();

        // Exit as the initial prover to set period end
        vm.prank(initialProver);
        proverManager.exit();

        // Warp to after exit delay to advance to next period
        vm.warp(block.timestamp + EXIT_DELAY + 1);

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        // Create a next publication header that's after the period end
        vm.warp(block.timestamp + EXIT_DELAY + 1);
        IPublicationFeed.PublicationHeader memory nextHeader = _insertPublication();

        // Create an array of publication headers to prove
        IPublicationFeed.PublicationHeader[] memory pubHeaders = new IPublicationFeed.PublicationHeader[](2);
        pubHeaders[0] = startHeader;
        pubHeaders[1] = endHeader;

        // Capture balances before proving
        uint256 prover1BalanceBefore = proverManager.balances(prover1);
        uint256 initialProverBalanceBefore = proverManager.balances(initialProver);

        // Have prover1 prove the closed period
        vm.warp(block.timestamp + PROVING_DEADLINE + 1);
        vm.prank(prover1);
        proverManager.proveClosedPeriod(
            startCheckpoint,
            endCheckpoint,
            pubHeaders,
            nextHeader,
            "0x", // any proof
            0
        );

        // Check that the initial prover received some fees (for work already done)
        uint256 initialProverBalanceAfter = proverManager.balances(initialProver);
        assertEq(
            initialProverBalanceAfter,
            initialProverBalanceBefore + INITIAL_FEE * 2,
            "Initial prover should receive some fees"
        );

        // Check that prover1 received the fees for the publications they proved plus part of the liveness bond
        uint256 prover1BalanceAfter = proverManager.balances(prover1);
        uint256 expectedFees = INITIAL_FEE * 2; // Two publications
        uint256 burnedStake = (LIVENESS_BOND * BURNED_STAKE_PERCENTAGE) / 10000;
        uint256 expectedLivenessBondReward = LIVENESS_BOND - burnedStake;

        assertEq(
            prover1BalanceAfter,
            prover1BalanceBefore + expectedFees + expectedLivenessBondReward,
            "Prover1 should receive correct amount of fees and liveness bond"
        );
    }

    function test_proveClosedPeriod_RevertWhen_PeriodStillOpen() public {
        // Setup: Create publications
        IPublicationFeed.PublicationHeader memory startHeader = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader = _insertPublication();

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        // Create a next publication header
        IPublicationFeed.PublicationHeader memory nextHeader = _insertPublication();

        // Create an array of publication headers to prove
        IPublicationFeed.PublicationHeader[] memory pubHeaders = new IPublicationFeed.PublicationHeader[](2);
        pubHeaders[0] = startHeader;
        pubHeaders[1] = endHeader;

        // Exit as the initial prover to set period end
        vm.prank(initialProver);
        proverManager.exit();

        // Attempt to prove a period that is still open(the deadline has not passed yet)
        vm.warp(block.timestamp + EXIT_DELAY + 1);
        vm.prank(prover1);
        vm.expectRevert("The period is still open");
        proverManager.proveClosedPeriod(
            startCheckpoint,
            endCheckpoint,
            pubHeaders,
            nextHeader,
            "0x", // any proof
            0
        );
    }

    // -- HELPERS --
    function _insertPublication() internal returns (IPublicationFeed.PublicationHeader memory) {
        bytes[] memory emptyAttributes = new bytes[](0);
        IPublicationFeed.PublicationHeader memory header = publicationFeed.publish(emptyAttributes);
        return header;
    }

    function _createPublicationHeader(uint256 id, uint256 timestamp, bytes32 prevHash, uint256 blockNumber)
        internal
        view
        returns (IPublicationFeed.PublicationHeader memory)
    {
        bytes32 attributesHash = keccak256(abi.encode("dummy"));
        return IPublicationFeed.PublicationHeader({
            id: id,
            publisher: msg.sender,
            timestamp: timestamp,
            prevHash: prevHash,
            blockNumber: blockNumber,
            attributesHash: attributesHash
        });
    }
}
