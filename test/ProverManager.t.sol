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
    uint256 constant REWARD_PERCENTAGE = 9000; // 90%
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
            rewardPercentage: REWARD_PERCENTAGE
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

        // Create a publication to trigger the new period
        vm.warp(vm.getBlockTimestamp() + 1);
        vm.prank(inbox);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
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
        _deposit(prover1, DEPOSIT_AMOUNT);

        // Withdraw 0.5 ether.
        uint256 balanceBefore = prover1.balance;
        vm.prank(prover1);
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
        assertApproxEqAbs(balanceAfter, balanceBefore + withdrawAmount, 1e15);
    }

    /// --------------------------------------------------------------------------
    /// payPublicationFee()
    /// --------------------------------------------------------------------------

    function test_payPublicationFee_SamePeriod() public {
        // Deposit funds for proposer.
        _deposit(proposer, DEPOSIT_AMOUNT);

        uint256 balanceBefore = proverManager.balances(proposer);
        // Call payPublicationFee from the inbox.
        vm.prank(inbox);
        proverManager.payPublicationFee{value: 0}(proposer, false);

        uint256 balanceAfter = proverManager.balances(proposer);
        assertEq(balanceAfter, balanceBefore - INITIAL_FEE, "Publication fee not deducted properly");
    }

    function test_payPublicationFee_AllowsToSendEth() public {
        // Call payPublicationFee from the inbox.
        vm.prank(inbox);
        vm.expectEmit();
        emit ProverManager.Deposit(proposer, DEPOSIT_AMOUNT);
        proverManager.payPublicationFee{value: DEPOSIT_AMOUNT}(proposer, false);

        uint256 balanceAfter = proverManager.balances(proposer);
        assertEq(balanceAfter, DEPOSIT_AMOUNT - INITIAL_FEE, "Publication fee not deducted properly");
    }

    function test_payPublicationFee_AdvancesPeriod() public {
        // Deposit funds for proposer.
        _deposit(proposer, DEPOSIT_AMOUNT);

        // Exit as a prover.
        _exit(initialProver);

        // Warp to a time after the period has ended.
        vm.warp(vm.getBlockTimestamp() + EXIT_DELAY + 1);

        // Call payPublicationFee from the inbox and check that the period has been advanced.
        vm.prank(inbox);
        vm.expectEmit();
        emit ProverManager.NewPeriod(2);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
    }

    function test_payPublicationFee_RevertWhen_NotInbox() public {
        vm.expectRevert("Only the Inbox contract can call this function");
        proverManager.payPublicationFee(prover1, false);
    }

    /// --------------------------------------------------------------------------
    /// bid()
    /// --------------------------------------------------------------------------
    function test_bid_ActivePeriod() public {
        // prover1 deposits sufficient funds
        _deposit(prover1, DEPOSIT_AMOUNT);

        uint256 maxAllowedFee = _maxAllowedFee(INITIAL_FEE);

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

    function test_bid_ExistingNextPeriod() public {
        // First, have prover1 make a successful bid
        _deposit(prover1, DEPOSIT_AMOUNT);

        uint256 firstBidFee = _maxAllowedFee(INITIAL_FEE);
        vm.prank(prover1);
        proverManager.bid(firstBidFee);

        // Now have prover2 outbid prover1
        _deposit(prover2, DEPOSIT_AMOUNT);

        // Calculate required fee for second bid
        uint256 secondBidFee = _maxAllowedFee(firstBidFee);

        vm.prank(prover2);
        vm.expectEmit();
        emit ProverManager.ProverOffer(prover2, 2, secondBidFee, LIVENESS_BOND);
        proverManager.bid(secondBidFee);

        // Check that period 2 now has prover2 as the prover
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
        _deposit(prover1, DEPOSIT_AMOUNT);

        // Record the current timestamp
        uint256 timestampBefore = vm.getBlockTimestamp();

        // Make a bid that will outbid the current prover
        uint256 bidFee = _maxAllowedFee(INITIAL_FEE);
        vm.prank(prover1);
        proverManager.bid(bidFee);

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
        _deposit(prover1, DEPOSIT_AMOUNT);

        uint256 firstBidFee = _maxAllowedFee(INITIAL_FEE);
        vm.prank(prover1);
        proverManager.bid(firstBidFee);

        // Now have prover2 try to bid with insufficient undercut
        _deposit(prover2, DEPOSIT_AMOUNT);

        uint256 maxFee = _maxAllowedFee(firstBidFee);
        uint256 insufficientlyReducedFee = maxFee + 1;

        vm.prank(prover2);
        vm.expectRevert("Offered fee not low enough");
        proverManager.bid(insufficientlyReducedFee);
    }

    function test_bid_RevertWhen_InsufficientBalance() public {
        // Attempt to bid without sufficient balance for liveness bond
        vm.prank(prover2);
        vm.expectRevert();
        proverManager.bid(_maxAllowedFee(INITIAL_FEE));
    }

    function test_bid_RevertWhen_FeeNotLowEnough() public {
        // prover1 deposits sufficient funds
        _deposit(prover1, DEPOSIT_AMOUNT);

        // Calculate a fee that's not low enough
        uint256 maxFee = _maxAllowedFee(INITIAL_FEE);
        uint256 insufficientlyReducedFee = maxFee + 1;

        vm.prank(prover1);
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
        uint256 incentive = _calculatePercentage(stakeBefore, EVICTOR_INCENTIVE_PERCENTAGE);

        // Evict the prover
        vm.warp(vm.getBlockTimestamp() + LIVENESS_WINDOW + 1);
        vm.prank(evictor);
        vm.expectEmit();
        emit ProverManager.ProverEvicted(
            initialProver, evictor, vm.getBlockTimestamp() + EXIT_DELAY, stakeBefore - incentive
        );
        proverManager.evictProver(header);

        // Verify period 1 is marked as evicted and its stake reduced
        ProverManager.Period memory periodAfter = proverManager.getPeriod(1);
        assertEq(periodAfter.deadline, vm.getBlockTimestamp() + EXIT_DELAY, "Prover should be evicted");
        assertEq(periodAfter.end, vm.getBlockTimestamp() + EXIT_DELAY, "Period end not set correctly");
        assertEq(periodAfter.stake, stakeBefore - incentive, "Stake not reduced correctly");

        // Verify that the evictor's balance increased by the incentive
        uint256 evictorBal = proverManager.balances(evictor);
        assertEq(evictorBal, incentive, "Evictor did not receive correct incentive");
    }

    function test_evictProver_RevertWhen_PublicationNotOldEnough() public {
        IPublicationFeed.PublicationHeader memory header = _insertPublication();

        // Evict the prover with a publication that is not old enough
        vm.warp(vm.getBlockTimestamp() + LIVENESS_WINDOW);
        vm.prank(evictor);
        vm.expectRevert("Publication is not old enough");
        proverManager.evictProver(header);
    }

    function test_evictProver_RevertWhen_InvalidPublicationHeader() public {
        uint256 initialTimestamp = vm.getBlockTimestamp();
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
        _exit(initialProver);

        // Evict the prover
        vm.warp(vm.getBlockTimestamp() + LIVENESS_WINDOW + 1);
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
        vm.warp(vm.getBlockTimestamp() + LIVENESS_WINDOW + 1);
        vm.prank(evictor);
        vm.expectRevert("Publication has been proven");
        proverManager.evictProver(header);
    }

    /// --------------------------------------------------------------------------
    /// exit()
    /// --------------------------------------------------------------------------
    function test_exit() public {
        // initialProver is the prover for period 1
        vm.prank(initialProver);
        vm.expectEmit();
        emit ProverManager.ProverExited(
            initialProver, vm.getBlockTimestamp() + EXIT_DELAY, vm.getBlockTimestamp() + EXIT_DELAY + PROVING_WINDOW
        );
        proverManager.exit();

        // Check that period 1 now has an end time and deadline set
        ProverManager.Period memory period = proverManager.getPeriod(1);
        assertEq(period.end, vm.getBlockTimestamp() + EXIT_DELAY, "Exit did not set period end correctly");
        assertEq(
            period.deadline, vm.getBlockTimestamp() + EXIT_DELAY + PROVING_WINDOW, "Proving deadline not set correctly"
        );
    }

    function test_exit_RevertWhen_NotCurrentProver() public {
        // Attempt to exit as a non-prover
        vm.prank(prover1);
        vm.expectRevert("Not current prover");
        proverManager.exit();
    }

    function test_exit_RevertWhen_AlreadyExited() public {
        // First exit
        _exit(initialProver);

        // Try to exit again
        vm.prank(initialProver);
        vm.expectRevert("Prover already exited");
        proverManager.exit();
    }

    /// --------------------------------------------------------------------------
    /// claimProvingVacancy()
    /// --------------------------------------------------------------------------
    function test_claimProvingVacancy() public {
        // First, have the current prover exit
        _exit(initialProver);

        vm.warp(vm.getBlockTimestamp() + EXIT_DELAY + 1);

        //Submit a publication to advance to the vacant period(period 2)
        vm.prank(inbox);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);

        // Ensure prover1 has enough funds
        _deposit(prover1, DEPOSIT_AMOUNT);

        // Claim the vacancy
        uint256 prover1BalanceBefore = proverManager.balances(prover1);
        uint256 newFee = 0.2 ether; //arbitrary new fee
        vm.prank(prover1);
        proverManager.claimProvingVacancy(newFee);

        // Check that period 2(the vacant period) has been closed correctly
        ProverManager.Period memory period2 = proverManager.getPeriod(2);
        assertEq(period2.end, vm.getBlockTimestamp(), "Period 2 end timestamp should be the current timestamp");
        assertEq(period2.deadline, vm.getBlockTimestamp(), "Period 2 deadline should be the current timestamp");

        // Check that period 3 has been created correctly
        ProverManager.Period memory period3 = proverManager.getPeriod(3);
        assertEq(period3.prover, prover1, "Prover1 should be the new prover");
        assertEq(period3.fee, newFee, "Fee should be set to the new fee");
        assertEq(period3.stake, LIVENESS_BOND, "Liveness bond should be locked");

        // // Check that prover1's balance was reduced by the liveness bond
        uint256 prover1BalanceAfter = proverManager.balances(prover1);
        assertEq(prover1BalanceAfter, prover1BalanceBefore - LIVENESS_BOND, "User balance not deducted correctly");
    }

    function test_claimProvingVacancy_AdvancesPeriod() public {
        // First, have the current prover exit to create a vacancy
        _exit(initialProver);

        vm.warp(vm.getBlockTimestamp() + EXIT_DELAY + 1);

        //Submit a publication to advance to the vacant period(period 2)
        vm.prank(inbox);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);

        // Ensure prover1 has enough funds
        _deposit(prover1, DEPOSIT_AMOUNT);

        // Verify the current period before claiming
        uint256 periodBefore = proverManager.currentPeriodId();

        // Claim the vacancy
        vm.prank(prover1);
        proverManager.claimProvingVacancy(0.2 ether);

        // Verify the period does not advance until a new publication is submitted
        uint256 periodAfter = proverManager.currentPeriodId();
        assertEq(periodAfter, periodBefore, "Period should not advance before a new publication is submitted");

        // Verify that a new publication advances the period
        vm.warp(vm.getBlockTimestamp() + 1);
        _deposit(proposer, INITIAL_FEE);
        vm.prank(inbox);
        vm.expectEmit();
        emit ProverManager.NewPeriod(periodAfter + 1);
        proverManager.payPublicationFee(proposer, false);
    }

    function test_claimProvingVacancy_RevertWhen_NoVacancy() public {
        // Attempt to claim a vacancy when the period is still active
        _deposit(prover1, DEPOSIT_AMOUNT);

        vm.prank(prover1);
        vm.expectRevert("No proving vacancy");
        proverManager.claimProvingVacancy(0.2 ether);
    }

    function test_claimProvingVacancy_RevertWhen_InsufficientBalance() public {
        // First, have the current prover exit to create a vacancy
        _exit(initialProver);

        vm.warp(vm.getBlockTimestamp() + EXIT_DELAY + 1);

        //Submit a publication to advance to the vacant period(period 2)
        vm.prank(inbox);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);

        // Attempt to claim the vacancy without sufficient balance
        vm.prank(prover2);
        vm.expectRevert();
        proverManager.claimProvingVacancy(0.2 ether);
    }

    /// --------------------------------------------------------------------------
    /// prove()
    /// --------------------------------------------------------------------------
    function test_prove_OpenPeriod() public {
        uint256 numRelevantPublications = 2;
        // Setup: Create publications and pay for the fees
        IPublicationFeed.PublicationHeader[] memory headers =
            _insertPublicationsWithFees(numRelevantPublications, INITIAL_FEE);
        IPublicationFeed.PublicationHeader memory startHeader = headers[0];
        IPublicationFeed.PublicationHeader memory endHeader = headers[1];

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id - 1,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

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
        uint256 numRelevantPublications = 2;
        // Setup: Create publications and pay for the fees
        IPublicationFeed.PublicationHeader[] memory headers =
            _insertPublicationsWithFees(numRelevantPublications, INITIAL_FEE);
        IPublicationFeed.PublicationHeader memory startHeader = headers[0];
        IPublicationFeed.PublicationHeader memory endHeader = headers[1];

        // Exit as the current prover to close the period
        _exit(initialProver);

        // Warp past the deadline
        vm.warp(vm.getBlockTimestamp() + EXIT_DELAY + PROVING_WINDOW + 1);

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id - 1,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

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
        assertTrue(periodAfter.pastDeadline, "Period should be marked as past deadline");

        // Verify prover1 received the fees
        uint256 prover1Balance = proverManager.balances(prover1);
        assertEq(prover1Balance, INITIAL_FEE * 2, "New prover should receive the fees");
    }

    function test_prove_ClosedPeriod_MultipleCalls() public {
        // Setup: Create publications and pay for the fees
        uint256 numPublications = 4;
        IPublicationFeed.PublicationHeader[] memory headers = _insertPublicationsWithFees(numPublications, INITIAL_FEE);
        IPublicationFeed.PublicationHeader memory startHeader1 = headers[0];
        IPublicationFeed.PublicationHeader memory startHeader2 = headers[2];
        IPublicationFeed.PublicationHeader memory endHeader2 = headers[3];

        // Exit as the current prover to close the period
        _exit(initialProver);
        vm.warp(vm.getBlockTimestamp() + EXIT_DELAY + PROVING_WINDOW + 1);

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

        // Verify the period is marked as past deadline
        ProverManager.Period memory periodAfter = proverManager.getPeriod(1);
        assertTrue(periodAfter.pastDeadline, "Period should be marked as past deadline");
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
        _exit(initialProver);

        // Create a publication after the period ends
        vm.warp(vm.getBlockTimestamp() + EXIT_DELAY + 1);
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
        _exit(initialProver);
        vm.warp(vm.getBlockTimestamp() + EXIT_DELAY + 1);

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
    /// finalizePastPeriod()
    /// --------------------------------------------------------------------------
    function test_finalizePastPeriod_WithinDeadline() public {
        uint256 numRelevantPublications = 2;
        // Setup: Create publications and pay for the fees
        IPublicationFeed.PublicationHeader[] memory headers =
            _insertPublicationsWithFees(numRelevantPublications, INITIAL_FEE);
        IPublicationFeed.PublicationHeader memory startHeader = headers[0];
        IPublicationFeed.PublicationHeader memory endHeader = headers[1];

        // Exit as the current prover to close the period
        _exit(initialProver);

        // Warp past the end
        vm.warp(block.timestamp + EXIT_DELAY + 1);

        // Create checkpoints for the publications
        ICheckpointTracker.Checkpoint memory startCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: startHeader.id - 1,
            commitment: keccak256(abi.encode("commitment1"))
        });
        ICheckpointTracker.Checkpoint memory endCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: endHeader.id,
            commitment: keccak256(abi.encode("commitment2"))
        });

        // Prove the publications
        proverManager.prove(
            startCheckpoint,
            endCheckpoint,
            startHeader,
            endHeader,
            numRelevantPublications,
            "0x", // any proof
            INITIAL_PERIOD
        );

        // Create a publication after the period ends
        vm.warp(block.timestamp + 1);
        IPublicationFeed.PublicationHeader memory afterPeriodHeader = _insertPublication();

        // Set the proven checkpoint to include the latest publication
        ICheckpointTracker.Checkpoint memory provenCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: afterPeriodHeader.id,
            commitment: keccak256(abi.encode("commitment3"))
        });
        checkpointTracker.setProvenHash(provenCheckpoint);

        uint256 initialProverBalanceBefore = proverManager.balances(initialProver);
        uint256 stakeBefore = proverManager.getPeriod(INITIAL_PERIOD).stake;

        // Finalize the first period
        proverManager.finalizePastPeriod(INITIAL_PERIOD, afterPeriodHeader);

        // Verify a portion of the stake was transferred to the prover
        ProverManager.Period memory periodAfter = proverManager.getPeriod(INITIAL_PERIOD);
        assertEq(periodAfter.stake, 0, "Stake should be zero after finalization");

        uint256 initialProverBalanceAfter = proverManager.balances(initialProver);
        assertEq(
            initialProverBalanceAfter,
            initialProverBalanceBefore + stakeBefore,
            "Prover should receive the remaining stake"
        );
    }

    function test_finalizePastPeriod_PastDeadline() public {
        uint256 numRelevantPublications = 2;

        // Setup: Create publications and pay for the fees
        IPublicationFeed.PublicationHeader[] memory headers =
            _insertPublicationsWithFees(numRelevantPublications, INITIAL_FEE);
        IPublicationFeed.PublicationHeader memory startHeader = headers[0];
        IPublicationFeed.PublicationHeader memory endHeader = headers[1];

        // Exit as the current prover to close the period
        _exit(initialProver);

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

        // Create a publication after the period ended
        IPublicationFeed.PublicationHeader memory afterPeriodHeader = _insertPublication();

        // Set the proven checkpoint to include the latest publication
        ICheckpointTracker.Checkpoint memory provenCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: afterPeriodHeader.id,
            commitment: keccak256(abi.encode("commitment3"))
        });
        checkpointTracker.setProvenHash(provenCheckpoint);

        uint256 initialProverBalanceBefore = proverManager.balances(initialProver);
        uint256 prover1BalanceBefore = proverManager.balances(prover1);
        uint256 stakeBefore = proverManager.getPeriod(INITIAL_PERIOD).stake;

        // Finalize the first period
        proverManager.finalizePastPeriod(INITIAL_PERIOD, afterPeriodHeader);

        // Verify a portion of the stake was transferred to prover1
        ProverManager.Period memory periodAfter = proverManager.getPeriod(INITIAL_PERIOD);
        assertEq(periodAfter.stake, 0, "Stake should be zero after finalization");

        uint256 initialProverBalanceAfter = proverManager.balances(initialProver);
        uint256 prover1BalanceAfter = proverManager.balances(prover1);
        uint256 stakeReward = _calculatePercentage(stakeBefore, REWARD_PERCENTAGE);
        assertEq(prover1BalanceAfter, prover1BalanceBefore + stakeReward, "Prover1 should receive the remaining stake");
        assertEq(initialProverBalanceAfter, initialProverBalanceBefore, "Initial prover should receive nothing");
    }

    function test_finalizePastPeriod_RevertWhen_PublicationNotProven() public {
        // Setup: Create publications and exit the period
        IPublicationFeed.PublicationHeader memory header = _insertPublication();
        _exit(initialProver);
        vm.warp(block.timestamp + EXIT_DELAY + 1);

        // Create a publication after the period ends
        vm.warp(block.timestamp + 1);
        IPublicationFeed.PublicationHeader memory afterPeriodHeader = _insertPublication();

        // Set the proven checkpoint to a lower publication ID
        ICheckpointTracker.Checkpoint memory provenCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: header.id, // Lower than afterPeriodHeader.id
            commitment: keccak256(abi.encode("commitment"))
        });
        checkpointTracker.setProvenHash(provenCheckpoint);

        // Attempt to finalize with unproven publication
        vm.expectRevert("Publication must be proven");
        proverManager.finalizePastPeriod(INITIAL_PERIOD, afterPeriodHeader);
    }

    function test_finalizePastPeriod_RevertWhen_PublicationNotAfterPeriod() public {
        // Setup: Create publications and exit the period
        _insertPublication();
        _exit(initialProver);

        // Create a publication before the period ends
        vm.warp(block.timestamp + EXIT_DELAY - 1);
        IPublicationFeed.PublicationHeader memory beforePeriodHeader = _insertPublication();

        // Set the proven checkpoint to a lower publication ID
        ICheckpointTracker.Checkpoint memory provenCheckpoint = ICheckpointTracker.Checkpoint({
            publicationId: beforePeriodHeader.id,
            commitment: keccak256(abi.encode("commitment"))
        });
        checkpointTracker.setProvenHash(provenCheckpoint);

        // Attempt to finalize with unproven publication
        vm.expectRevert("Publication must be after period");
        proverManager.finalizePastPeriod(INITIAL_PERIOD, beforePeriodHeader);
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
        _exit(initialProver);

        // Bid as a new prover
        _deposit(prover1, DEPOSIT_AMOUNT);
        uint256 bidFee = INITIAL_FEE * 2;
        vm.prank(prover1);
        proverManager.bid(bidFee);

        // Warp to a time after the period has ended.
        vm.warp(vm.getBlockTimestamp() + EXIT_DELAY + 1);
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

    function _insertPublicationsWithFees(uint256 numPublications, uint256 fee)
        internal
        returns (IPublicationFeed.PublicationHeader[] memory)
    {
        IPublicationFeed.PublicationHeader[] memory headers = new IPublicationFeed.PublicationHeader[](numPublications);
        for (uint256 i = 0; i < numPublications; i++) {
            headers[i] = _insertPublication();
            vm.prank(inbox);
            proverManager.payPublicationFee{value: fee}(proposer, false);
        }
        return headers;
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

    function _deposit(address user, uint256 amount) internal {
        vm.prank(user);
        proverManager.deposit{value: amount}();
    }

    function _maxAllowedFee(uint256 fee) internal pure returns (uint256) {
        return _calculatePercentage(fee, MAX_BID_PERCENTAGE);
    }

    function _calculatePercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return amount * percentage / 10_000;
    }

    function _exit(address prover) internal {
        vm.prank(prover);
        proverManager.exit();
    }
}
