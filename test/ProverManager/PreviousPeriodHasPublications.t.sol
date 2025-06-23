// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CurrentPeriodHasPublications} from "./CurrentPeriodHasPublications.t.sol";

import {LibPercentage} from "src/libs/LibPercentage.sol";
import {LibProvingPeriod} from "src/libs/LibProvingPeriod.sol";
import {BaseProverManager} from "src/protocol/BaseProverManager.sol";
import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";
import {IInbox} from "src/protocol/IInbox.sol";

/// Represents states where the previous period has existing publications (that can be proven).
/// This performs the same tests as CurrentPeriodHasPublications except it applies to proofs for the previous period.
/// We could merge them and check every period but that is probably excessive.
/// This also includes tests to finalize the previous period. For simplicity (since no other tests are affected),
/// we treat the "pastDeadline" options as different tests rather than different states.
abstract contract PreviousPeriodHasPublications is CurrentPeriodHasPublications {
    // This is a sanity check to ensure we're in the expected state
    function test_PreviousPeriodHasPublications_confirmPreconditions() public view {
        uint256 periodId = proverManager.currentPeriodId();
        assertGe(periodId, 0, "No previous period exists");
    }

    function test_PreviousPeriodHasPublications_prove_shouldRevertWithUnknownFirstPublication() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        _proveWholePeriod(periodId);
        inbox.setInvalidHeader(firstPub);
        vm.expectRevert(BaseProverManager.FirstPublicationDoesNotExist.selector);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_PreviousPeriodHasPublications_prove_shouldRevertWithUnknownLastPublication() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        _proveWholePeriod(periodId);
        inbox.setInvalidHeader(lastPub);
        vm.expectRevert(BaseProverManager.LastPublicationDoesNotExist.selector);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_PreviousPeriodHasPublications_prove_shouldRevertWithMismatchedStartCheckpoint() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        _proveWholePeriod(periodId);
        firstPub.id = start.publicationId;
        vm.expectRevert(BaseProverManager.InvalidStartPublication.selector);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_PreviousPeriodHasPublications_prove_shouldRevertWithMismatchedEndCheckpoint() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        _proveWholePeriod(periodId);
        lastPub.id = end.publicationId + 1;
        vm.expectRevert(BaseProverManager.LastPublicationMismatch.selector);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_PreviousPeriodHasPublications_prove_shouldRevertIfFirstPublicationInPreviousPeriod() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        _proveWholePeriod(periodId);
        firstPub.timestamp -= 1;
        vm.expectRevert(BaseProverManager.FirstPublicationIsBeforePeriod.selector);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_PreviousPeriodHasPublications_prove_shouldRevertIfLastPublicationAfterPeriod() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        _proveWholePeriod(periodId);
        lastPub.timestamp += 1;
        // revert if the period has an end timestamp (and the last pub is after it)
        uint64 numReverts = proverManager.getPeriod(periodId).end == 0 ? 0 : 1;
        vm.expectRevert(BaseProverManager.LastPublicationIsAfterPeriod.selector, numReverts);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_PreviousPeriodHasPublications_prove_shouldRevertIfProofFails() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        _proveWholePeriod(periodId);
        checkpointTracker.setValid(false);
        vm.expectRevert();
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_PreviousPeriodHasPublications_prove_shouldCreditProver() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        _proveWholePeriod(periodId);
        LibProvingPeriod.Period memory periodBefore = proverManager.getPeriod(periodId);

        uint256 standardFee =
            periodBefore.fee * (checkpointTracker.nPublications() - checkpointTracker.nDelayedPublications());
        uint256 delayedFee = LibPercentage.scaleByPercentage(periodBefore.fee, periodBefore.delayedFeePercentage)
            * checkpointTracker.nDelayedPublications();
        uint256 reward = standardFee + delayedFee;

        bool isDeadlinePassed = periodBefore.deadline != 0 && vm.getBlockTimestamp() > periodBefore.deadline;
        address newProver = isDeadlinePassed ? proverB : periodBefore.prover;

        uint256 escrowedBefore = _currencyBalance(address(proverManager));
        uint256 balanceBefore = proverManager.balances(newProver);

        vm.prank(proverB);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));
        uint256 balanceAfter = proverManager.balances(newProver);
        LibProvingPeriod.Period memory periodAfter = proverManager.getPeriod(periodId);

        assertEq(escrowedAfter, escrowedBefore, "Value held by ProverManager changed");
        assertEq(balanceAfter, balanceBefore + reward, "Balance not updated correctly");
        assertEq(periodAfter.pastDeadline, isDeadlinePassed, "PastDeadline flag set incorrectly");
        assertEq(periodAfter.prover, newProver, "New prover set incorrectly");
    }

    function test_PreviousPeriodHasPublications_finalizePastPeriod_shouldRevertWithUnknownPublication() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        IInbox.PublicationHeader memory provenPublication;
        inbox.setInvalidHeader(provenPublication);
        vm.expectRevert(BaseProverManager.InvalidPublication.selector);
        proverManager.finalizePastPeriod(periodId, provenPublication);
    }

    function test_PreviousPeriodHasPublications_finalizePastPeriod_shouldRevertWithUnprovenPublication() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        IInbox.PublicationHeader memory provenPublication; // despite the name this will be unproven.
        provenPublication.id = checkpointTracker.provenPublicationId() + 1;
        vm.expectRevert(BaseProverManager.PublicationNotProven.selector);
        proverManager.finalizePastPeriod(periodId, provenPublication);
    }

    function test_PreviousPeriodHasPublications_finalizePastPeriod_cannotFinalizeVacantPeriod() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        IInbox.PublicationHeader memory provenPublication;
        provenPublication.id = checkpointTracker.provenPublicationId();
        address prover = proverManager.getPeriod(periodId).prover;
        vm.expectRevert(BaseProverManager.PeriodNotInitialized.selector, prover == address(0) ? 1 : 0);
        proverManager.finalizePastPeriod(periodId, provenPublication);
    }

    function test_PreviousPeriodHasPublications_finalizePastPeriod_shouldRevertWithEarlyPublication() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        LibProvingPeriod.Period memory period = proverManager.getPeriod(periodId);
        if (period.prover == address(0)) return; // skip vacant periods

        IInbox.PublicationHeader memory provenPublication;
        provenPublication.id = checkpointTracker.provenPublicationId();
        provenPublication.timestamp = period.end;
        vm.expectRevert(BaseProverManager.PublicationNotAfterPeriod.selector);
        proverManager.finalizePastPeriod(periodId, provenPublication);
    }

    function test_PreviousPeriodHasPublications_finalizePastPeriod_shouldFinalizePeriod() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        LibProvingPeriod.Period memory periodBefore = proverManager.getPeriod(periodId);
        if (periodBefore.prover == address(0)) return; // skip vacant periods

        IInbox.PublicationHeader memory provenPublication;
        provenPublication.id = checkpointTracker.provenPublicationId();
        provenPublication.timestamp = periodBefore.end + 1;
        proverManager.finalizePastPeriod(periodId, provenPublication);

        LibProvingPeriod.Period memory periodAfter = proverManager.getPeriod(periodId);
        assertEq(periodAfter.prover, address(0), "Prover not cleared");
        assertEq(periodAfter.stake, 0, "Stake not cleared");
    }

    function test_PreviousPeriodHasPublications_finalizePastPeriod_shouldReturnFullStakeToTimelyProver() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        LibProvingPeriod.Period memory period = proverManager.getPeriod(periodId);
        if (period.prover == address(0)) return; // skip vacant periods

        // This is the default situation, so this is just a pre-condition check.
        assertFalse(period.pastDeadline, "Period had missed deadline");

        IInbox.PublicationHeader memory provenPublication;
        provenPublication.id = checkpointTracker.provenPublicationId();
        provenPublication.timestamp = period.end + 1;

        uint256 escrowedBefore = _currencyBalance(address(proverManager));
        uint256 balanceBefore = proverManager.balances(period.prover);

        proverManager.finalizePastPeriod(periodId, provenPublication);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));
        uint256 balanceAfter = proverManager.balances(period.prover);

        assertEq(escrowedAfter, escrowedBefore, "Value held by ProverManager changed");
        assertEq(balanceAfter, balanceBefore + period.stake, "Balance not updated correctly");
    }

    function test_PreviousPeriodHasPublications_finalizePastPeriod_shouldTransferReducedStakeToNewestProver() public {
        uint256 periodId = proverManager.currentPeriodId() - 1;
        LibProvingPeriod.Period memory period = proverManager.getPeriod(periodId);
        if (period.prover == address(0)) return; // skip vacant periods
        if (period.deadline == 0 || vm.getBlockTimestamp() <= period.deadline) return; // skip periods within deadline

        // Prove the period now (after the deadline) to set the `pastDeadline` flag
        _proveWholePeriod(periodId);
        vm.prank(proverB);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
        LibProvingPeriod.Period memory periodAfterProof = proverManager.getPeriod(periodId);
        assertTrue(periodAfterProof.pastDeadline, "Period proven within deadline");
        assertEq(periodAfterProof.prover, proverB, "Period not assigned to new prover");

        IInbox.PublicationHeader memory provenPublication;
        provenPublication.id = checkpointTracker.provenPublicationId();
        provenPublication.timestamp = period.end + 1;

        uint256 escrowedBefore = _currencyBalance(address(proverManager));
        uint256 balanceBefore = proverManager.balances(proverB);

        proverManager.finalizePastPeriod(periodId, provenPublication);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));
        uint256 balanceAfter = proverManager.balances(proverB);
        uint256 rewardAmount = LibPercentage.scaleByBPS(period.stake, proverManager.rewardFraction());

        assertEq(escrowedAfter, escrowedBefore, "Value held by ProverManager changed");
        assertEq(balanceAfter, balanceBefore + rewardAmount, "Balance not updated correctly");
    }
}
