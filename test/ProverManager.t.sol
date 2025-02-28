// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ProverManager} from "../src/protocol/taiko_alethia/ProverManager.sol";
import {CheckpointTracker} from "src/protocol/CheckpointTracker.sol";
import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";
import {PublicationFeed} from "src/protocol/PublicationFeed.sol";
import {NullVerifier} from "test/mocks/NullVerifier.sol";

contract RegisterProverTest is Test {
    // contracts
    ProverManager public proverManager;
    CheckpointTracker tracker;
    NullVerifier verifier;
    PublicationFeed feed;
    address public inboxAddress;

    //actors
    address public admin = address(0x1);
    address public prover1 = address(0x2);
    address public prover2 = address(0x3);

    bytes32[] pubHashes;
    ICheckpointTracker.Checkpoint[] checkpoints;
    bytes32[] hashes;
    bytes proof;

    uint256 public NUM_PUBLICATIONS = 10;
    uint256 EXCESS_CHECKPOINTS;

    // Prover Manager Paramas
    uint256 public constant MIN_STEP_PERCENTAGE = 500; // 5%
    uint256 public constant OLD_PUBLICATION_WINDOW = 1 days;
    uint256 public constant OFFER_ACTIVATION_DELAY = 3 days;
    uint256 public constant EXIT_DELAY = 7 days;
    uint256 public constant DELAYED_FEE_MULTIPLIER = 2;
    uint256 public constant PROVING_DEADLINE = 1 days;
    uint256 public constant LIVENESS_BOND = 10 ether;
    uint256 public constant EVICTOR_INCENTIVE_PERCENTAGE = 1000; // 10%
    uint256 public constant BURNED_STAKE_PERCENTAGE = 5000; // 50%

    function setUp() public {
        vm.startPrank(admin);

        inboxAddress = address(0x1234);
        verifier = new NullVerifier();

        feed = new PublicationFeed();
        createSampleFeed();

        proverManager = new ProverManager(
            MIN_STEP_PERCENTAGE,
            OLD_PUBLICATION_WINDOW,
            OFFER_ACTIVATION_DELAY,
            EXIT_DELAY,
            DELAYED_FEE_MULTIPLIER,
            PROVING_DEADLINE,
            LIVENESS_BOND,
            EVICTOR_INCENTIVE_PERCENTAGE,
            BURNED_STAKE_PERCENTAGE,
            inboxAddress,
            address(tracker),
            address(feed)
        );

        tracker =
            new CheckpointTracker(keccak256(abi.encode(0)), address(feed), address(verifier), address(proverManager));
        createSampleCheckpoints();
        proof = abi.encode("proof");
        vm.stopPrank();

        vm.deal(prover1, 20 ether);
        vm.deal(prover2, 20 ether);
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

    function calculateUnderbidFee(uint256 amount) private pure returns (uint256) {
        return amount * (10000 - MIN_STEP_PERCENTAGE) / 10000;
    }

    function test_Prover1UnderbidsProver2() public {
        uint256 initialFee = 0.01 ether;

        vm.startPrank(prover1);
        proverManager.deposit{value: LIVENESS_BOND}();
        assertEq(proverManager.balances(prover1), LIVENESS_BOND);
        proverManager.registerProver(initialFee);
        vm.stopPrank();

        (address registeredProver, uint256 livenessBond, uint256 accumulatedFees, uint256 fee,,,) =
            proverManager.periods(1);

        assertEq(registeredProver, prover1);
        assertEq(livenessBond, LIVENESS_BOND);
        assertEq(fee, initialFee);
        assertEq(accumulatedFees, 0);
        assertEq(proverManager.balances(prover1), LIVENESS_BOND);

        uint256 underbidFee = calculateUnderbidFee(initialFee);

        vm.startPrank(prover2);
        proverManager.deposit{value: LIVENESS_BOND}();
        // console.log("Prover2 balance: ", proverManager.balances(prover2));
        // console.log("Prover1 balance: ", proverManager.balances(prover1));
        proverManager.registerProver(underbidFee);
        vm.stopPrank();

        // // Check that prover2 has replaced prover1 for the next period
        // (address newRegisteredProver, uint256 newLivenessBond,, uint256 newFee,,,) =
        //     proverManager.periods(proverManager.currentPeriodId() + 1);
        //
        // assertEq(newRegisteredProver, prover2);
        // assertEq(newLivenessBond, LIVENESS_BOND);
        // assertEq(newFee, underbidFee);
        // assertEq(proverManager.balances(prover2), LIVENESS_BOND);
        // assertEq(proverManager.balances(prover1), 0);
        //
        // // Verify prover1 got their liveness bond back
        // assertEq(proverManager.balances(prover1), LIVENESS_BOND);
    }
}
