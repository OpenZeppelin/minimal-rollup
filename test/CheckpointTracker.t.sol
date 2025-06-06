// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, Vm} from "forge-std/Test.sol";
import {CheckpointTracker} from "src/protocol/CheckpointTracker.sol";
import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";

import {ICommitmentStore} from "src/protocol/ICommitmentStore.sol";
import {PublicationFeed} from "src/protocol/PublicationFeed.sol";

import {SignalService} from "src/protocol/SignalService.sol";
import {NullVerifier} from "test/mocks/NullVerifier.sol";

contract CheckpointTrackerTest is Test {
    CheckpointTracker tracker;
    NullVerifier verifier;
    PublicationFeed feed;
    SignalService signalService;
    // For the unit tests, we do it without a prover manager
    address proverManager = address(0);
    address rollupOperator = makeAddr("rollup");

    // Sample data
    bytes32[] pubHashes;
    ICheckpointTracker.Checkpoint[] checkpoints;
    bytes32[] hashes;
    bytes proof;

    uint256 constant NUM_PUBLICATIONS = 20;
    uint256 constant ZERO_DELAYED_PUBLICATIONS = 0;

    function setUp() public {
        verifier = new NullVerifier();

        feed = new PublicationFeed();

        signalService = new SignalService();

        tracker = new CheckpointTracker(
            keccak256(abi.encode("genesis")), address(feed), address(verifier), proverManager, address(signalService)
        );

        createSampleFeed();

        vm.prank(rollupOperator);
        proof = abi.encode("proof");
    }

    function test_setUp() public view {
        ICheckpointTracker.Checkpoint memory genesisCheckpoint =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("genesis"))});
        ICheckpointTracker.Checkpoint memory provenCheckpoint = tracker.getProvenCheckpoint();
        assertEq(provenCheckpoint.publicationId, genesisCheckpoint.publicationId);
        assertEq(provenCheckpoint.commitment, genesisCheckpoint.commitment);
    }

    function test_constructor_RevertWhenGenesisIsZero() public {
        vm.expectRevert("genesis checkpoint commitment cannot be 0");
        new CheckpointTracker(bytes32(0), address(feed), address(verifier), proverManager, address(signalService));
    }

    // function test_constructor_EmitsEvent() public {
    //     bytes32 genesisCommitment = keccak256(abi.encode("genesis"));
    //     ICheckpointTracker.Checkpoint memory genesisCheckpoint =
    //         ICheckpointTracker.Checkpoint({publicationId: 0, commitment: genesisCommitment});
    //
    //     vm.expectEmit();
    //     emit ICheckpointTracker.CheckpointUpdated(genesisCheckpoint.publicationId, genesisCheckpoint.commitment);
    //     new CheckpointTracker(
    //         genesisCommitment, address(feed), address(verifier), proverManager, address(signalService)
    //     );
    // }
    //
    function test_proveTransition_SuccessfulTransition() public {
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 3, commitment: keccak256(abi.encode("end"))});
        uint256 numRelevantPublications = 2;

        vm.expectEmit();
        emit ICheckpointTracker.CheckpointUpdated(end.publicationId, end.commitment);

        // Empty checkpoint needed to comply with the interface, but not used in `CheckpointTracker`
        ICheckpointTracker.Checkpoint memory emptyCheckpoint =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: bytes32(0)});
        tracker.proveTransition(emptyCheckpoint, end, numRelevantPublications, ZERO_DELAYED_PUBLICATIONS, proof);

        ICheckpointTracker.Checkpoint memory provenCheckpoint = tracker.getProvenCheckpoint();
        assertEq(provenCheckpoint.publicationId, end.publicationId);
        assertEq(provenCheckpoint.commitment, end.commitment);
    }

    function test_proveTransition_RevertWhenEndCommitmentIsZero() public {
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 3, commitment: bytes32(0)});
        uint256 numRelevantPublications = 2;

        // Empty checkpoint needed to comply with the interface, but not used in `CheckpointTracker`
        ICheckpointTracker.Checkpoint memory emptyCheckpoint =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: bytes32(0)});
        vm.expectRevert("Checkpoint commitment cannot be 0");
        tracker.proveTransition(emptyCheckpoint, end, numRelevantPublications, ZERO_DELAYED_PUBLICATIONS, proof);
    }

    function test_proveTransition_RevertWhenNumDelayedPublicationsGreaterThanNumPublications() public {
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 3, commitment: keccak256(abi.encode("end"))});
        uint256 numRelevantPublications = 2;
        uint256 numDelayedPublications = 3;

        // Empty checkpoint needed to comply with the interface, but not used in `CheckpointTracker`
        ICheckpointTracker.Checkpoint memory emptyCheckpoint =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: bytes32(0)});
        vm.expectRevert("Number of delayed publications cannot be greater than the total number of publications");
        tracker.proveTransition(emptyCheckpoint, end, numRelevantPublications, numDelayedPublications, proof);
    }

    function createSampleFeed() private {
        pubHashes = new bytes32[](NUM_PUBLICATIONS);

        bytes[] memory emptyAttributes = new bytes[](0);
        for (uint256 i; i < NUM_PUBLICATIONS; ++i) {
            feed.publish(emptyAttributes);
            pubHashes[i] = feed.getPublicationHash(i);
        }
    }

    function createCheckpoint(uint256 pubId, bytes32 commitment)
        private
        pure
        returns (ICheckpointTracker.Checkpoint memory checkpoint, bytes32 hash)
    {
        checkpoint = ICheckpointTracker.Checkpoint({publicationId: pubId, commitment: commitment});
        hash = keccak256(abi.encode(checkpoint));
    }
}
