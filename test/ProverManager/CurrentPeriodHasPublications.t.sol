// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UniversalTest} from "./UniversalTest.t.sol";

import {LibPercentage} from "src/libs/LibPercentage.sol";
import {LibProvingPeriod} from "src/libs/LibProvingPeriod.sol";
import {BaseProverManager} from "src/protocol/BaseProverManager.sol";
import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";
import {IInbox} from "src/protocol/IInbox.sol";

/// Represents states that have existing publications (that can be proven). Since the BaseProverManager does not track
/// publications, this can apply to any state (we decide the publications on a per-test basis)
/// Nevertheless, this contract is used to better encaspulate the proving tests
abstract contract CurrentPeriodHasPublications is UniversalTest {
    ICheckpointTracker.Checkpoint start;
    ICheckpointTracker.Checkpoint end;
    IInbox.PublicationHeader firstPub;
    IInbox.PublicationHeader lastPub;
    bytes proof = new bytes(0);

    function test_CurrentPeriodHasPublications_prove_shouldRevertWithUnknownFirstPublication() public {
        uint256 periodId = proverManager.currentPeriodId();
        _proveWholePeriod(periodId);
        inbox.setInvalidHeader(firstPub);
        vm.expectRevert(BaseProverManager.FirstPublicationDoesNotExist.selector);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_CurrentPeriodHasPublications_prove_shouldRevertWithUnknownLastPublication() public {
        uint256 periodId = proverManager.currentPeriodId();
        _proveWholePeriod(periodId);
        inbox.setInvalidHeader(lastPub);
        vm.expectRevert(BaseProverManager.LastPublicationDoesNotExist.selector);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_CurrentPeriodHasPublications_prove_shouldRevertWithMismatchedStartCheckpoint() public {
        uint256 periodId = proverManager.currentPeriodId();
        _proveWholePeriod(periodId);
        firstPub.id = start.publicationId;
        vm.expectRevert(BaseProverManager.InvalidStartPublication.selector);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_CurrentPeriodHasPublications_prove_shouldRevertWithMismatchedEndCheckpoint() public {
        uint256 periodId = proverManager.currentPeriodId();
        _proveWholePeriod(periodId);
        lastPub.id = end.publicationId + 1;
        vm.expectRevert(BaseProverManager.LastPublicationMismatch.selector);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_CurrentPeriodHasPublications_prove_shouldRevertIfFirstPublicationInPreviousPeriod() public {
        uint256 periodId = proverManager.currentPeriodId();
        _proveWholePeriod(periodId);
        firstPub.timestamp -= 1;
        vm.expectRevert(BaseProverManager.FirstPublicationIsBeforePeriod.selector);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_CurrentPeriodHasPublications_prove_shouldRevertIfLastPublicationAfterPeriod() public {
        uint256 periodId = proverManager.currentPeriodId();
        _proveWholePeriod(periodId);
        lastPub.timestamp += 1;
        // revert if the period has an end timestamp (and the last pub is after it)
        uint64 numReverts = proverManager.getPeriod(periodId).end == 0 ? 0 : 1;
        vm.expectRevert(BaseProverManager.LastPublicationIsAfterPeriod.selector, numReverts);
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_CurrentPeriodHasPublications_prove_shouldRevertIfProofFails() public {
        uint256 periodId = proverManager.currentPeriodId();
        _proveWholePeriod(periodId);
        checkpointTracker.setValid(false);
        vm.expectRevert();
        proverManager.prove(start, end, firstPub, lastPub, proof, periodId);
    }

    function test_CurrentPeriodHasPublications_prove_shouldCreditProver() public {
        uint256 periodId = proverManager.currentPeriodId();
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

    // construct a proof consistent with the MockCheckpointTracker and covers publications that span the whole period
    function _proveWholePeriod(uint256 periodId) internal {
        uint40 periodEnd = proverManager.getPeriod(periodId).end;
        uint40 previousPeriodEnd = periodId > 0 ? proverManager.getPeriod(periodId - 1).end : 0;

        start.publicationId = checkpointTracker.provenPublicationId();
        end.publicationId = start.publicationId + checkpointTracker.nPublications();
        end.totalDelayedPublications = start.totalDelayedPublications + checkpointTracker.nDelayedPublications();
        firstPub.id = start.publicationId + 1;
        firstPub.timestamp = previousPeriodEnd + 1;
        lastPub.id = end.publicationId;
        lastPub.timestamp = periodEnd == 0 ? vm.getBlockTimestamp() : periodEnd;
    }
}
