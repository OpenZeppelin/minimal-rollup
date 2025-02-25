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
    address proverMananger = vm.addr(1);

    // Sample data
    bytes32[] pubHashes;
    ICheckpointTracker.Checkpoint[] checkpoints;
    bytes32[] hashes;
    bytes proof;

    uint256 NUM_PUBLICATIONS;
    uint256 EXCESS_CHECKPOINTS;

    function setUp() public {
        NUM_PUBLICATIONS = 20;
        EXCESS_CHECKPOINTS = 5;

        verifier = new NullVerifier();

        feed = new PublicationFeed();
        createSampleFeed();

        tracker = new CheckpointTracker(keccak256(abi.encode(0)), address(feed), address(verifier), proverMananger);
        createSampleCheckpoints();
        proof = abi.encode("proof");
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

    function createSampleCheckpoints() private {
        ICheckpointTracker.Checkpoint memory memCheckpoint;
        bytes32 checkpointHash;
        for (uint256 i; i < NUM_PUBLICATIONS + EXCESS_CHECKPOINTS; ++i) {
            (memCheckpoint, checkpointHash) = createCheckpoint(i, keccak256(abi.encode(i)));
            checkpoints.push(memCheckpoint);
            hashes.push(checkpointHash);
        }
    }

    function test_Setup_CheckpointIsGenesis() public view {
        assertEq(tracker.provenHash(), hashes[0]);
    }

    function test_DisconnectedTransition_ProvenUnchanged() public {
        tracker.proveTransition(checkpoints[3], checkpoints[5], proof);
        assertEq(tracker.provenHash(), hashes[0]);
    }

    function test_DisconnectedTransition_TransitionUpdated() public {
        assertEq(tracker.transitions(hashes[3]), 0);
        tracker.proveTransition(checkpoints[3], checkpoints[5], proof);
        assertNotEq(tracker.transitions(hashes[3]), 0);
        assertEq(tracker.transitions(hashes[3]), hashes[5]);
    }

    function test_NextTransition_ProvenUpdated() public {
        tracker.proveTransition(checkpoints[0], checkpoints[5], proof);
        assertNotEq(tracker.provenHash(), hashes[0]);
        assertEq(tracker.provenHash(), hashes[5]);
    }

    function test_NextTransition_TransitionNotUpdated() public {
        assertEq(tracker.transitions(hashes[0]), 0);
        tracker.proveTransition(checkpoints[0], checkpoints[5], proof);
        assertEq(tracker.transitions(hashes[0]), 0);
    }

    function testRevert_DuplicateTransition() public {
        tracker.proveTransition(checkpoints[3], checkpoints[5], proof);
        vm.expectRevert();
        tracker.proveTransition(checkpoints[3], checkpoints[7], proof);
    }

    function testRevert_TransitionOutOfBounds() public {
        vm.expectRevert();
        tracker.proveTransition(checkpoints[18], checkpoints[23], proof);
    }

    function test_LastTransition() public {
        // does not revert
        tracker.proveTransition(checkpoints[18], checkpoints[NUM_PUBLICATIONS], proof);
    }

    function testRevert_BackwardsTransition() public {
        vm.expectRevert();
        tracker.proveTransition(checkpoints[5], checkpoints[3], proof);
    }

    function test_TwoStepUpdate() public {
        tracker.proveTransition(checkpoints[6], checkpoints[8], proof);
        assertEq(tracker.provenHash(), hashes[0]); // checkpoint not updated
        assertEq(tracker.transitions(hashes[6]), hashes[8]);

        tracker.proveTransition(checkpoints[0], checkpoints[6], proof);
        assertEq(tracker.provenHash(), hashes[8]); // checkpoint updated over both transitions
    }

    function test_ChainedUpdates() public {
        // 6 -> 8
        tracker.proveTransition(checkpoints[6], checkpoints[8], proof);
        assertEq(tracker.provenHash(), hashes[0]); // checkpoint not updated
        assertEq(tracker.transitions(hashes[6]), hashes[8]);

        // 2 -> 6 -> 8
        tracker.proveTransition(checkpoints[2], checkpoints[6], proof);
        assertEq(tracker.provenHash(), hashes[0]); // checkpoint not updated
        assertEq(tracker.transitions(hashes[2]), hashes[6]);

        // 2 -> 6 -> 8 -> 11
        tracker.proveTransition(checkpoints[8], checkpoints[11], proof);
        assertEq(tracker.provenHash(), hashes[0]); // checkpoint not updated
        assertEq(tracker.transitions(hashes[8]), hashes[11]);

        // 2 -> 6 -> 8 -> 11; 15 -> 16
        tracker.proveTransition(checkpoints[15], checkpoints[16], proof);
        assertEq(tracker.provenHash(), hashes[0]); // checkpoint not updated
        assertEq(tracker.transitions(hashes[15]), hashes[16]);

        tracker.proveTransition(checkpoints[0], checkpoints[2], proof);
        // checkpoint updated over chain (to 11) but not to latest checkpoint (16)
        assertEq(tracker.provenHash(), hashes[11]);
    }

    function test_UpdateLimits() public {
        // set up individual transitions between 2 to 15
        for (uint256 i = 2; i < 15; i++) {
            tracker.proveTransition(checkpoints[i], checkpoints[i + 1], proof);
        }

        // prove 0 -> 2 to start the chain of updates
        tracker.proveTransition(checkpoints[0], checkpoints[2], proof);
        // do exactly MAX_EXTRA_UPDATES (10) additional updates
        assertEq(tracker.provenHash(), hashes[12]);

        // another proof will complete the update chain
        tracker.proveTransition(checkpoints[17], checkpoints[19], proof);
        assertEq(tracker.provenHash(), hashes[15]);
    }
}
