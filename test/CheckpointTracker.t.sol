// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {CheckpointTracker} from "src/protocol/CheckpointTracker.sol";
import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";
import {PublicationFeed} from "src/protocol/PublicationFeed.sol";
import {NullVerifier} from "test/mocks/NullVerifier.sol";

contract CheckpointTrackerTest is Test {
    CheckpointTracker tracker;
    NullVerifier verifier;
    PublicationFeed feed;
    // For the unit tests, we do it without a prover manager
    address proverManager = address(0);

    // Sample data
    bytes32[] pubHashes;
    ICheckpointTracker.Checkpoint[] checkpoints;
    bytes32[] hashes;
    bytes proof;

    uint256 NUM_PUBLICATIONS;

    function setUp() public {
        NUM_PUBLICATIONS = 20;

        verifier = new NullVerifier();

        feed = new PublicationFeed();
        createSampleFeed();

        tracker =
            new CheckpointTracker(keccak256(abi.encode("genesis")), address(feed), address(verifier), proverManager);
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
        new CheckpointTracker(bytes32(0), address(feed), address(verifier), proverManager);
    }

    function test_constructor_EmitsEvent() public {
        bytes32 genesisCheckpoint = keccak256(abi.encode("genesis"));
        ICheckpointTracker.Checkpoint memory genesisCheckpoint =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: genesisCheckpoint});

        vm.expectEmit();
        emit ICheckpointTracker.CheckpointUpdated(genesisCheckpoint);
        new CheckpointTracker(genesisCheckpoint, address(feed), address(verifier), proverManager);
    }

    function test_proveTransition_SuccessfulTransition() public {
        ICheckpointTracker.Checkpoint memory start =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("genesis"))});
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 3, commitment: keccak256(abi.encode("end"))});
        uint256 numRelevantPublications = 2;

        vm.expectEmit();
        emit ICheckpointTracker.CheckpointUpdated(end);
        tracker.proveTransition(start, end, numRelevantPublications, proof);

        ICheckpointTracker.Checkpoint memory provenCheckpoint = tracker.getProvenCheckpoint();
        assertEq(provenCheckpoint.publicationId, end.publicationId);
        assertEq(provenCheckpoint.commitment, end.commitment);
    }

    function test_proveTransition_RevertWhenEndCheckpointIsZero() public {
        ICheckpointTracker.Checkpoint memory start =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("genesis"))});
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 3, commitment: bytes32(0)});
        uint256 numRelevantPublications = 2;

        vm.expectRevert("Checkpoint commitment cannot be 0");
        tracker.proveTransition(start, end, numRelevantPublications, proof);
    }

    function test_proveTransition_RevertWhenStartCheckpointNotLatestProven() public {
        ICheckpointTracker.Checkpoint memory start =
            ICheckpointTracker.Checkpoint({publicationId: 1, commitment: keccak256(abi.encode("wrong"))});
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 3, commitment: keccak256(abi.encode("end"))});
        uint256 numRelevantPublications = 2;

        vm.expectRevert("Start checkpoint must be the latest proven checkpoint");
        tracker.proveTransition(start, end, numRelevantPublications, proof);
    }

    function test_proveTransition_RevertWhenEndPublicationNotAfterStart() public {
        ICheckpointTracker.Checkpoint memory start =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("genesis"))});
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("end"))});
        // this is nonsensical, but we're testing the publicationId check so I think it makes sense for the other
        // parameters to match previous tests.
        uint256 numRelevantPublications = 2;

        vm.expectRevert("End publication must be after the last proven publication");
        tracker.proveTransition(start, end, numRelevantPublications, proof);
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
