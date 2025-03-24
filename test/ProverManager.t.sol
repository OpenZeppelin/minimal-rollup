// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ProverManager} from "../src/protocol/taiko_alethia/ProverManager.sol";

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";
import {IPublicationFeed} from "src/protocol/IPublicationFeed.sol";
import {PublicationFeed} from "src/protocol/PublicationFeed.sol";

import {MockCheckpointTracker} from "test/mocks/MockCheckpointTracker.sol";
import {NullVerifier} from "test/mocks/NullVerifier.sol";

contract ProverManagerTest is Test {
    ProverManager proverManager;
    MockCheckpointTracker checkpointTracker;
    NullVerifier verifier;
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
    uint256 constant MAX_BID_PERCENTAGE = 9500; // 95%
    uint256 constant LIVENESS_WINDOW = 60; // 60 seconds
    uint256 constant SUCCESSION_DELAY = 10;
    uint256 constant EXIT_DELAY = 10;
    uint256 constant PROVING_WINDOW = 30;
    uint256 constant LIVENESS_BOND = 1 ether;
    uint256 constant EVICTOR_INCENTIVE_PERCENTAGE = 500; // 5%
    uint256 constant BURNED_STAKE_PERCENTAGE = 1000; // 10%
    uint256 constant INITIAL_FEE = 0.1 ether;
    uint256 constant INITIAL_PERIOD = 1;

    function setUp() public {
        checkpointTracker = new MockCheckpointTracker();
        publicationFeed = new PublicationFeed();

        // Fund the initial prover so the constructor can receive the required livenessBond.
        vm.deal(initialProver, 10 ether);

        // Create the config struct for the constructor
        ProverManager.ProverManagerConfig memory config = ProverManager.ProverManagerConfig({
            maxBidPercentage: MAX_BID_PERCENTAGE,
            livenessWindow: LIVENESS_WINDOW,
            successionDelay: SUCCESSION_DELAY,
            exitDelay: EXIT_DELAY,
            provingWindow: PROVING_WINDOW,
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

    function test_payPublicationFee_AdvancesPeriod() public {
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
        emit ProverManager.NewPeriod(2);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
    }

    /// --------------------------------------------------------------------------
    /// bid()
    /// --------------------------------------------------------------------------
    function test_bid_ActivePeriod() public {
        // prover1 deposits sufficient funds
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 maxAllowedFee = INITIAL_FEE * MAX_BID_PERCENTAGE / 10000;

        vm.prank(prover1);
        vm.expectEmit();
        emit ProverManager.ProverOffer(prover1, 2, maxAllowedFee, LIVENESS_BOND);
        proverManager.bid(maxAllowedFee);

        // Check that period 2 has been created
        ProverManager.Period memory period = proverManager.getPeriod(2);

        assertEq(period.prover, prover1, "Bid not recorded for new period");
        assertEq(period.fee, maxAllowedFee, "Offered fee not set correctly");
        assertEq(period.stake, LIVENESS_BOND, "Liveness bond not locked");
        assertEq(period.end, 0, "Period end should be zero until active");
        assertEq(period.deadline, 0, "Deadline should be zero until active");

        // Check that prover1's balance was reduced by the liveness bond
        uint256 prover1Bal = proverManager.balances(prover1);
        assertEq(prover1Bal, DEPOSIT_AMOUNT - LIVENESS_BOND, "User balance not deducted correctly");
    }

    function test_bid_RevertWhen_InsufficientBalance() public {
        // Attempt to bid without sufficient balance for liveness bond
        vm.prank(prover2);
        vm.expectRevert();
        proverManager.bid(0.05 ether);
    }

    function test_bid_RevertWhen_FeeNotLowEnough() public {
        // prover1 deposits sufficient funds
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        // Calculate a fee that's not low enough
        uint256 maxFee = INITIAL_FEE * MAX_BID_PERCENTAGE / 10000;
        uint256 insufficientlyReducedFee = maxFee + 1;

        vm.prank(prover1);
        vm.expectRevert("Offered fee not low enough");
        proverManager.bid(insufficientlyReducedFee);
    }

    function test_bid_ExistingNextPeriod() public {
        // First, have prover1 make a successful bid
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 firstBidFee = INITIAL_FEE * MAX_BID_PERCENTAGE / 10000;
        vm.prank(prover1);
        proverManager.bid(firstBidFee);

        // Now have prover2 outbid prover1
        vm.prank(prover2);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        // Calculate required fee for second bid
        uint256 secondBidFee = firstBidFee * MAX_BID_PERCENTAGE / 10000;

        vm.prank(prover2);
        vm.expectEmit();
        emit ProverManager.ProverOffer(prover2, 2, secondBidFee, LIVENESS_BOND);
        proverManager.bid(secondBidFee);

        // Check that period 1 now has prover2 as the prover
        ProverManager.Period memory period = proverManager.getPeriod(2);
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
        uint256 bidFee = INITIAL_FEE * MAX_BID_PERCENTAGE / 10000;
        vm.prank(prover1);
        proverManager.bid(bidFee);

        // Check that period 0 now has an end time set
        ProverManager.Period memory period = proverManager.getPeriod(1);
        assertEq(
            period.end,
            timestampBefore + SUCCESSION_DELAY,
            "Period end should be set to current time + succession delay"
        );
        assertEq(
            period.deadline, timestampBefore + SUCCESSION_DELAY + PROVING_WINDOW, "Deadline should be set correctly"
        );
    }

    function test_bid_RevertWhen_NotEnoughUndercutOnNextPeriod() public {
        // First, have prover1 make a successful bid
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 firstBidFee = INITIAL_FEE * MAX_BID_PERCENTAGE / 10000;
        vm.prank(prover1);
        proverManager.bid(firstBidFee);

        // Now have prover2 try to bid with insufficient undercut
        vm.prank(prover2);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();

        uint256 maxFee = firstBidFee * MAX_BID_PERCENTAGE / 10000;
        uint256 insufficientlyReducedFee = maxFee + 1;

        vm.prank(prover2);
        vm.expectRevert("Offered fee not low enough");
        proverManager.bid(insufficientlyReducedFee);
    }

    /// --------------------------------------------------------------------------
    /// evictProver()
    /// --------------------------------------------------------------------------
    function test_evictProver() public {
        IPublicationFeed.PublicationHeader memory header = _insertPublication();

        // Capture current period stake before eviction
        ProverManager.Period memory periodBefore = proverManager.getPeriod(1);
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
        proverManager.evictProver(header);

        // Verify period 1 is marked as evicted and its stake reduced
        ProverManager.Period memory periodAfter = proverManager.getPeriod(1);
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

        // Evict the prover with a publication that is not old enough
        vm.warp(block.timestamp + LIVENESS_WINDOW);
        vm.prank(evictor);
        vm.expectRevert("Publication is not old enough");
        proverManager.evictProver(header);
    }

    function test_evictProver_RevertWhen_InvalidPublicationHeader() public {
        uint256 initialTimestamp = block.timestamp;
        vm.warp(initialTimestamp + LIVENESS_WINDOW + 1);

        IPublicationFeed.PublicationHeader memory header = _insertPublication();
        // Tamper with the header
        header.timestamp = initialTimestamp;

        // Evict the prover with an invalid publication header
        vm.prank(evictor);
        vm.expectRevert("Invalid publication");
        proverManager.evictProver(header);
    }

    function test_evictProver_RevertWhen_PeriodNotActive() public {
        IPublicationFeed.PublicationHeader memory header = _insertPublication();

        // Exit the period, setting and end to the period
        vm.prank(initialProver);
        proverManager.exit();

        // Evict the prover
        vm.warp(block.timestamp + LIVENESS_WINDOW + 1);
        vm.prank(evictor);
        vm.expectRevert("Proving period is not active");
        proverManager.evictProver(header);
    }

    function test_evictProver_RevertWhen_ProvenCheckpoint() public {
        IPublicationFeed.PublicationHeader memory header = _insertPublication();

        // Advance the proven checkpoint on the mock checkpoint tracker
        ICheckpointTracker.Checkpoint memory provenCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: header.id + 1,
            commitment: keccak256(abi.encode("commitment"))
        });
        checkpointTracker.setProvenHash(provenCheckpoint);

        // Evict the prover
        vm.warp(block.timestamp + LIVENESS_WINDOW + 1);
        vm.prank(evictor);
        vm.expectRevert("Publication has been proven");
        proverManager.evictProver(header);
    }

    /// --------------------------------------------------------------------------
    /// exit()
    /// --------------------------------------------------------------------------
    function test_exit() public {
        // initialProver is the prover for period 0
        vm.prank(initialProver);
        vm.expectEmit();
        emit ProverManager.ProverExited(
            initialProver, block.timestamp + EXIT_DELAY, block.timestamp + EXIT_DELAY + PROVING_WINDOW
        );
        proverManager.exit();

        // Check that period 1 now has an end time and deadline set
        ProverManager.Period memory period = proverManager.getPeriod(1);
        assertEq(period.end, block.timestamp + EXIT_DELAY, "Exit did not set period end correctly");
        assertEq(period.deadline, block.timestamp + EXIT_DELAY + PROVING_WINDOW, "Proving deadline not set correctly");
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
    /// prove()
    /// --------------------------------------------------------------------------
    function test_prove_OpenPeriod() public {
        // Setup: Create publications and pay for the fees
        IPublicationFeed.PublicationHeader memory startHeader = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader = _insertPublication();
        vm.startPrank(inbox);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
        vm.stopPrank();

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id - 1,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });
        uint256 numRelevantPublications = 2;

        // // Prove the publications
        uint256 proverBalanceBefore = proverManager.balances(initialProver);

        proverManager.prove(
            startCheckpoint,
            endCheckpoint,
            startHeader,
            endHeader,
            numRelevantPublications,
            "0x", // any proof
            INITIAL_PERIOD
        );

        uint256 proverBalanceAfter = proverManager.balances(initialProver);
        assertEq(proverBalanceAfter, proverBalanceBefore + INITIAL_FEE * 2, "Prover should receive fees");
    }

    function test_prove_ClosedPeriod() public {
        // Setup: Create publications and pay for the fees
        IPublicationFeed.PublicationHeader memory startHeader = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader = _insertPublication();
        vm.startPrank(inbox);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
        vm.stopPrank();

        // Exit as the current prover to close the period
        vm.prank(initialProver);
        proverManager.exit();

        // Warp past the deadline
        vm.warp(block.timestamp + EXIT_DELAY + PROVING_WINDOW + 1);

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id - 1,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });
        uint256 numRelevantPublications = 2;

        // Capture stake before proving
        ProverManager.Period memory periodBefore = proverManager.getPeriod(1);
        uint256 stakeBefore = periodBefore.stake;
        uint256 expectedBurnedStake = (stakeBefore * BURNED_STAKE_PERCENTAGE) / 10000;

        // Prove the publications with a different prover
        vm.prank(prover1);
        proverManager.prove(
            startCheckpoint,
            endCheckpoint,
            startHeader,
            endHeader,
            numRelevantPublications,
            "0x", // any proof
            INITIAL_PERIOD
        );

        // Verify period 1 has been updated
        ProverManager.Period memory periodAfter = proverManager.getPeriod(1);
        assertEq(periodAfter.prover, prover1, "Prover should be updated to the new prover");
        assertEq(periodAfter.stake, stakeBefore - expectedBurnedStake, "Stake should be reduced by burn percentage");
        assertTrue(periodAfter.pastDeadline, "Period should be marked as past deadline");

        // Verify prover1 received the fees
        uint256 prover1Balance = proverManager.balances(prover1);
        assertEq(prover1Balance, INITIAL_FEE * 2, "New prover should receive the fees");
    }

    function test_prove_ClosedPeriod_MultipleCalls() public {
        // Setup: Create publications and pay for the fees
        IPublicationFeed.PublicationHeader memory startHeader1 = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader1 = _insertPublication();
        IPublicationFeed.PublicationHeader memory startHeader2 = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader2 = _insertPublication();
        vm.startPrank(inbox);
        proverManager.payPublicationFee{value: INITIAL_FEE * 4}(proposer, false);
        vm.stopPrank();

        // Exit as the current prover to close the period
        vm.prank(initialProver);
        proverManager.exit();
        vm.warp(block.timestamp + EXIT_DELAY + PROVING_WINDOW + 1);

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader1.id - 1,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader2.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        uint256 prover1BalanceBefore = proverManager.balances(prover1);
        ProverManager.Period memory periodBefore = proverManager.getPeriod(1);
        uint256 stakeBefore = periodBefore.stake;
        uint256 expectedBurnedStake = (stakeBefore * BURNED_STAKE_PERCENTAGE) / 10000;

        // Prove the publications with prover1
        vm.prank(prover1);
        proverManager.prove(startCheckpoint, endCheckpoint, startHeader1, endHeader2, 2, "0x", INITIAL_PERIOD);

        // Prove the other publications with prover2
        startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader2.id - 1,
            commitment: keccak256(abi.encode("commitment3"))
        });
        endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader2.id,
            commitment: keccak256(abi.encode("commitment4"))
        });
        vm.prank(prover2);
        proverManager.prove(startCheckpoint, endCheckpoint, startHeader2, endHeader2, 2, "0x", INITIAL_PERIOD);

        // Verify prover1 received the fees
        uint256 prover1BalanceAfter = proverManager.balances(prover1);
        assertEq(prover1BalanceAfter, prover1BalanceBefore + INITIAL_FEE * 2, "Prover1 should receive the fees");

        // Verify prover2 received the fees
        uint256 prover2BalanceAfter = proverManager.balances(prover2);
        assertEq(prover2BalanceAfter, INITIAL_FEE * 2, "Prover2 should receive the fees");

        // Verify the burn happened only once
        ProverManager.Period memory periodAfter = proverManager.getPeriod(1);
        assertEq(periodAfter.stake, stakeBefore - expectedBurnedStake, "Stake should be reduced by burn percentage");
    }

    function test_prove_RevertWhen_LastPublicationDoesNotMatchEndCheckpoint() public {
        // Setup: Create publications
        IPublicationFeed.PublicationHeader memory startHeader = _insertPublication();
        IPublicationFeed.PublicationHeader memory endHeader = _insertPublication();

        // Create checkpoints with mismatched publication ID
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id - 1,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id + 1, // Mismatch with endHeader.id
            commitment: keccak256(abi.encode("commitment2"))
        });

        // Attempt to prove with mismatched end checkpoint
        vm.expectRevert("Last publication does not match end checkpoint");
        proverManager.prove(startCheckpoint, endCheckpoint, startHeader, endHeader, 2, "0x", INITIAL_PERIOD);
    }

    function test_prove_RevertWhen_LastPublicationAfterPeriodEnd() public {
        // Setup: Create publications
        IPublicationFeed.PublicationHeader memory startHeader = _insertPublication();

        // Exit as the current prover to set period end
        vm.prank(initialProver);
        proverManager.exit();

        // Create a publication after the period ends
        vm.warp(block.timestamp + EXIT_DELAY + 1);
        IPublicationFeed.PublicationHeader memory lateHeader = _insertPublication();

        // Create checkpoints
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id - 1,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: lateHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        // Attempt to prove with publication after period end
        vm.expectRevert("Last publication is after the period");
        proverManager.prove(startCheckpoint, endCheckpoint, startHeader, lateHeader, 2, "0x", INITIAL_PERIOD);
    }

    function test_prove_RevertWhen_FirstPublicationNotAfterStartCheckpoint() public {
        // Setup: Create publications
        IPublicationFeed.PublicationHeader memory firstHeader = _insertPublication();
        IPublicationFeed.PublicationHeader memory lastHeader = _insertPublication();

        // Create checkpoints with incorrect start checkpoint
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: firstHeader.id, // Should be firstHeader.id - 1
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: lastHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        vm.expectRevert("First publication not immediately after start checkpoint");
        proverManager.prove(startCheckpoint, endCheckpoint, firstHeader, lastHeader, 2, "0x", INITIAL_PERIOD);
    }

    function test_prove_RevertWhen_FirstPublicationBeforePeriod() public {
        // Create a publication in period 1
        IPublicationFeed.PublicationHeader memory earlyHeader = _insertPublication();

        // Exit as the current prover to set period end
        vm.prank(initialProver);
        proverManager.exit();
        vm.warp(block.timestamp + EXIT_DELAY + 1);

        // Create a publication in period 2
        IPublicationFeed.PublicationHeader memory lateHeader = _insertPublication();

        // Create checkpoints
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: earlyHeader.id - 1,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: lateHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        // Attempt to prove with first publication before period 2
        vm.expectRevert("First publication is before the period");
        proverManager.prove(startCheckpoint, endCheckpoint, earlyHeader, lateHeader, 2, "0x", INITIAL_PERIOD + 1);
    }

    /// --------------------------------------------------------------------------
    /// getCurrentFees()
    /// --------------------------------------------------------------------------

    function test_getCurrentFees_SamePeriod() public view {
        (uint256 fee, uint256 delayedFee) = proverManager.getCurrentFees();
        assertEq(fee, INITIAL_FEE, "Fee should be the initial fee");
        assertEq(delayedFee, INITIAL_FEE, "Delayed fee should be the initial fee");
    }

    function test_geCurrentFees_WhenPeriodEnded() public {
        // Exit as a prover.
        vm.prank(initialProver);
        proverManager.exit();

        // Bid as a new prover
        vm.prank(prover1);
        proverManager.deposit{value: DEPOSIT_AMOUNT}();
        uint256 bidFee = INITIAL_FEE * 2;
        vm.prank(prover1);
        proverManager.bid(bidFee);

        // Warp to a time after the period has ended.
        vm.warp(block.timestamp + EXIT_DELAY + 1);
        (uint256 fee, uint256 delayedFee) = proverManager.getCurrentFees();
        assertEq(fee, bidFee, "Fee should be the bid fee");
        assertEq(delayedFee, bidFee, "Delayed fee should be the bid fee");
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
