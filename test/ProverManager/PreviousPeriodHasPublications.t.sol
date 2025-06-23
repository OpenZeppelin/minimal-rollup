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
        uint256 periodId = proverManager.currentPeriodId() -1;
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
        LibProvingPeriod.Period memory period = proverManager.getPeriod(periodId);

        uint256 standardFee =
            period.fee * (checkpointTracker.nPublications() - checkpointTracker.nDelayedPublications());
        uint256 delayedFee = LibPercentage.scaleByPercentage(period.fee, period.delayedFeePercentage)
            * checkpointTracker.nDelayedPublications();
        uint256 reward = standardFee + delayedFee;

        bool isDeadlinePassed = period.deadline != 0 && vm.getBlockTimestamp() > period.deadline;
        address prover = isDeadlinePassed ? proverB : period.prover;

        uint256 escrowedBefore = _currencyBalance(address(proverManager));
        uint256 balanceBefore = proverManager.balances(prover);

        vm.prank(proverB);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);

        uint256 escrowedAfter = _currencyBalance(address(proverManager));
        uint256 balanceAfter = proverManager.balances(prover);

        assertEq(escrowedAfter, escrowedBefore, "Value held by ProverManager changed");
        assertEq(balanceAfter, balanceBefore + reward, "Balance not updated correctly");
        assertEq(proverManager.getPeriod(periodId).pastDeadline, isDeadlinePassed, "PastDeadline flag set incorrectly");
    }
}
