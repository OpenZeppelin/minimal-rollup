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

        tracker = new CheckpointTracker(keccak256(abi.encode("genesis")), address(feed), address(verifier));
        proof = abi.encode("proof");
    }

    function test_setUp() public {
        ICheckpointTracker.Checkpoint memory genesisCheckpoint =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("genesis"))});
        assertEq(tracker.provenHash(), keccak256(abi.encode(genesisCheckpoint)));
    }

    function test_constructor_RevertWhenGenesisIsZero() public {
        vm.expectRevert("genesis checkpoint commitment cannot be 0");
        new CheckpointTracker(bytes32(0), address(feed), address(verifier));
    }

    function test_constructor_EmitsEvent() public {
        ICheckpointTracker.Checkpoint memory genesisCheckpoint =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("genesis"))});
        bytes32 genesisHash = keccak256(abi.encode(genesisCheckpoint));

        vm.expectEmit();
        emit ICheckpointTracker.CheckpointUpdated(genesisHash);
        new CheckpointTracker(keccak256(abi.encode("genesis")), address(feed), address(verifier));
    }

    function test_proveTransition_SuccessfulTransition() public {
        ICheckpointTracker.Checkpoint memory start =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("genesis"))});
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 3, commitment: keccak256(abi.encode("end"))});

        vm.expectEmit();
        emit ICheckpointTracker.TransitionProven(start, end);
        tracker.proveTransition(start, end, proof);

        assertEq(tracker.provenHash(), keccak256(abi.encode(end)));
    }

    function test_proveTransition_RevertWhenEndCommitmentIsZero() public {
        ICheckpointTracker.Checkpoint memory start =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("genesis"))});
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 3, commitment: bytes32(0)});

        vm.expectRevert("Checkpoint commitment cannot be 0");
        tracker.proveTransition(start, end, proof);
    }

    function test_proveTransition_RevertWhenStartCheckpointNotLatestProven() public {
        ICheckpointTracker.Checkpoint memory start =
            ICheckpointTracker.Checkpoint({publicationId: 1, commitment: keccak256(abi.encode("wrong"))});
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 3, commitment: keccak256(abi.encode("end"))});

        vm.expectRevert("Start checkpoint must be the latest proven checkpoint");
        tracker.proveTransition(start, end, proof);
    }

    function test_proveTransition_RevertWhenEndPublicationNotAfterStart() public {
        ICheckpointTracker.Checkpoint memory start =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("genesis"))});
        ICheckpointTracker.Checkpoint memory end =
            ICheckpointTracker.Checkpoint({publicationId: 0, commitment: keccak256(abi.encode("end"))});

        vm.expectRevert("End publication must be after the last proven publication");
        tracker.proveTransition(start, end, proof);
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
