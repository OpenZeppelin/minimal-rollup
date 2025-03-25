// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {ProverManager} from "../../src/protocol/taiko_alethia/ProverManager.sol";

import {PublicationFeed} from "src/protocol/PublicationFeed.sol";

import {MockCheckpointTracker} from "test/mocks/MockCheckpointTracker.sol";
import {NullVerifier} from "test/mocks/NullVerifier.sol";

contract InitialState is Test {
    ProverManager proverManager;
    MockCheckpointTracker checkpointTracker;
    NullVerifier verifier;
    PublicationFeed publicationFeed;

    // Addresses used for testing
    address deployer = _randomAddress("deployer");
    address inbox = _randomAddress("inbox");
    address initialProver = _randomAddress("initialProver");

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

        // Fund the deployer so the constructor can receive the required livenessBond.
        vm.deal(deployer, 10 ether);

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
    }

    function _randomAddress(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encode(_domainSeparator(), name)))));
    }

    function _domainSeparator() internal pure returns (bytes32) {
        return keccak256("InitialState");
    }
}
