// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {MockInbox} from "./mocks/MockInbox.sol";
import {MockVerifier} from "./mocks/MockVerifier.sol";
import "forge-std/Test.sol";
import {CheckpointTracker} from "src/protocol/CheckpointTracker.sol";
import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";
import {SignalService} from "src/protocol/SignalService.sol";

contract CheckpointTrackerTest is Test {
    CheckpointTracker tracker;
    MockInbox inbox;
    MockVerifier verifier;
    SignalService signalService;
    address proverManager = makeAddr("proverManager");
    bytes32 genesis = keccak256(abi.encode("genesis"));

    ICheckpointTracker.Checkpoint start;
    ICheckpointTracker.Checkpoint end;
    bytes proof = new bytes(0);

    function setUp() public {
        inbox = new MockInbox();
        verifier = new MockVerifier();
        signalService = new SignalService();
        tracker =
            new CheckpointTracker(genesis, address(inbox), address(verifier), proverManager, address(signalService));
    }

    function test_constructor_shouldRevertWithZeroGenesis() public {
        vm.expectRevert(ICheckpointTracker.ZeroGenesisCommitment.selector);
        new CheckpointTracker(bytes32(0), address(inbox), address(verifier), proverManager, address(signalService));
    }

    function test_constructor_shouldSetExternalContracts() public view {
        assertEq(address(tracker.inbox()), address(inbox), "Did not set inbox");
        assertEq(address(tracker.verifier()), address(verifier), "Did not set verifier");
        assertEq(address(tracker.commitmentStore()), address(signalService), "Did not set commitment store");
        assertEq(address(tracker.proverManager()), proverManager, "Did not set prover manager");
    }

    function test_constructor_shouldSetProvenPublicationId() public view {
        assertEq(tracker.provenPublicationId(), inbox.getNextPublicationId() - 1, "Proven publication set incorrectly");
    }

    function test_constructor_shouldSaveGenesisCommitment() public view {
        bytes32 savedCommitment = signalService.commitmentAt(address(tracker), tracker.provenPublicationId());
        assertEq(savedCommitment, genesis, "Did not save genesis");
    }

    function test_proveTransition_shouldRevertIfNotCalledByProverManager() public {
        _constructValidTransition();
        vm.expectRevert(ICheckpointTracker.OnlyProverManager.selector);
        tracker.proveTransition(start, end, proof);
    }

    function test_proveTransition_shouldRevertIfStartCommitmentIsZero() public {
        _constructValidTransition();
        start.commitment = bytes32(0);
        vm.expectRevert(ICheckpointTracker.ZeroStartCommitment.selector);
        vm.prank(proverManager);
        tracker.proveTransition(start, end, proof);
    }

    function test_proveTransition_shouldRevertIfEndCommitmentIsZero() public {
        _constructValidTransition();
        end.commitment = bytes32(0);
        vm.expectRevert(ICheckpointTracker.ZeroEndCommitment.selector);
        vm.prank(proverManager);
        tracker.proveTransition(start, end, proof);
    }

    function test_proveTransition_shouldRevertIfStartPublicationIsNotProven() public {
        _constructValidTransition();
        start.publicationId = tracker.provenPublicationId() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                ICheckpointTracker.InvalidStartPublication.selector, start.publicationId, tracker.provenPublicationId()
            )
        );
        vm.prank(proverManager);
        tracker.proveTransition(start, end, proof);
    }

    function test_proveTransition_shouldNotRevertIfAllPublicationsAreDelayed() public {
        _constructValidTransition();
        end.totalDelayedPublications = start.totalDelayedPublications + (end.publicationId - start.publicationId);
        vm.prank(proverManager);
        tracker.proveTransition(start, end, proof);
    }

    function test_proveTransition_shouldRevertIfDelayedPublicationsExceedPublications() public {
        _constructValidTransition();
        uint256 numPublications = end.publicationId - tracker.provenPublicationId();
        uint256 numDelayed = start.totalDelayedPublications + (end.publicationId - start.publicationId) + 1;
        end.totalDelayedPublications = numDelayed;

        vm.expectRevert(
            abi.encodeWithSelector(
                ICheckpointTracker.ExcessiveDelayedPublications.selector, numDelayed, numPublications
            )
        );
        vm.prank(proverManager);
        tracker.proveTransition(start, end, proof);
    }

    function test_proveTransition_shouldRevertWithUnknownEndPublication() public {
        _constructValidTransition();
        end.publicationId = inbox.getNextPublicationId();
        vm.expectRevert(ICheckpointTracker.EndPublicationNotFound.selector);
        vm.prank(proverManager);
        tracker.proveTransition(start, end, proof);
    }

    function test_proveTransition_shouldRevertWithInvalidProof() public {
        _constructValidTransition();
        verifier.setValidity(false);
        vm.expectRevert();
        vm.prank(proverManager);
        tracker.proveTransition(start, end, proof);
    }

    function test_proveTransition_shouldUpdateProvenPublication() public {
        _constructValidTransition();
        vm.prank(proverManager);
        tracker.proveTransition(start, end, proof);
        assertEq(tracker.provenPublicationId(), end.publicationId, "Proven publication not end publication");
    }

    function test_proveTransition_shouldSaveEndCommitment() public {
        _constructValidTransition();
        vm.prank(proverManager);
        tracker.proveTransition(start, end, proof);
        bytes32 savedCommitment = signalService.commitmentAt(address(tracker), tracker.provenPublicationId());
        assertEq(savedCommitment, end.commitment, "Did not save end commitment");
    }

    function test_proveTransition_shouldEmitEvent() public {
        _constructValidTransition();
        vm.prank(proverManager);
        vm.expectEmit();
        emit ICheckpointTracker.CommitmentSaved(end.publicationId, end.commitment);
        tracker.proveTransition(start, end, proof);
    }

    function test_shouldReturnPublicationCounts() public {
        _constructValidTransition();
        vm.prank(proverManager);
        (uint256 nPublications, uint256 nDelayed) = tracker.proveTransition(start, end, proof);
        // assume there is no front-running proof that advances provenPublicationId
        assertEq(nPublications, end.publicationId - start.publicationId, "Incorrect publication count");
        uint256 expectedDelayedCount = end.totalDelayedPublications - start.totalDelayedPublications;
        assertEq(nDelayed, expectedDelayedCount, "Incorrect delayed publication count");
    }

    function test_shouldAllowOverlappingProof() public {
        // Submit the first proof
        _constructValidTransition();
        vm.prank(proverManager);
        tracker.proveTransition(start, end, proof);
        assertEq(tracker.provenPublicationId(), end.publicationId, "Proven publication not set correctly");

        // The second proof has the same start but it covers 6 more publications, 1 of them delayed
        inbox.publishMultiple(5);
        end.publicationId += 6;
        end.totalDelayedPublications += 1;
        end.commitment = keccak256(abi.encode("newEnd"));

        vm.prank(proverManager);
        (uint256 nPublications, uint256 nDelayed) = tracker.proveTransition(start, end, proof);

        assertEq(tracker.provenPublicationId(), end.publicationId, "Proven publication not updated correctly");
        assertEq(nPublications, 6, "Number of publications does not match extension");
        assertEq(nDelayed, 1, "Number of delayed publications does not match extension");
    }

    // an arbitrary transition
    function _constructValidTransition() public {
        // ensure there are some publications to prover
        inbox.publishMultiple(10);

        start.publicationId = tracker.provenPublicationId();
        start.commitment = keccak256(abi.encode("start"));
        start.totalDelayedPublications = 0;

        end.publicationId = start.publicationId + 5;
        end.commitment = keccak256(abi.encode("end"));
        end.totalDelayedPublications = start.totalDelayedPublications + 2;
    }
}
