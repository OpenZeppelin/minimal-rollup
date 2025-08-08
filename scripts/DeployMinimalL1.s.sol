// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BlobRefRegistry} from "../src/blobs/BlobRefRegistry.sol";
import {IBlobRefRegistry} from "../src/blobs/IBlobRefRegistry.sol";
import {CheckpointTracker} from "../src/protocol/CheckpointTracker.sol";

import {ILookahead} from "../src/protocol/ILookahead.sol";
import {IProposerFees} from "../src/protocol/IProposerFees.sol";
import {TaikoInbox} from "../src/protocol/taiko_alethia/TaikoInbox.sol";

import {SignalService} from "../src/protocol/SignalService.sol";
import {MockVerifier} from "../test/mocks/MockVerifier.sol";

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";

/// @title Deploy L1 Taiko Contracts
/// @notice Script to deploy the TaikoInbox contract
contract DeployL1Contracts is Script {
    function run() public {
        vm.startBroadcast();

        // --- config params ----
        address lookaheadAddr = vm.envOr("TAIKO_LOOKAHEAD_ADDRESS", address(0));
        uint256 maxAnchorBlockIdOffset = vm.envOr("TAIKO_MAX_ANCHOR_BLOCK_ID_OFFSET", uint256(100));
        uint256 inclusionDelay = vm.envOr("TAIKO_INCLUSION_DELAY", uint256(1 hours));
        bytes32 genesis = vm.envOr("TAIKO_GENESIS_HASH", keccak256(abi.encode("genesis")));

        console.log("------- CONFIG ------");
        console.log("Lookahead address:", lookaheadAddr);
        console.log("Max Anchor Block Id Offset:", maxAnchorBlockIdOffset);
        console.log("Inclusion Delay:", inclusionDelay);
        console.log("Genesis:", genesis);
        console.log("------------------------");

        // ------deployments--------
        BlobRefRegistry blobRefRegistry = new BlobRefRegistry();
        TaikoInbox taikoInbox = new TaikoInbox(
            lookaheadAddr, address(blobRefRegistry), maxAnchorBlockIdOffset, inclusionDelay
        );

        MockVerifier verifier = new MockVerifier();

        SignalService signalService = new SignalService();

        CheckpointTracker tracker = new CheckpointTracker(
            genesis,
            address(taikoInbox),
            address(verifier),
            address(signalService)
        );

        vm.stopBroadcast();

        console.log("");
        console.log("------- DEPLOYMENTS ------");
        console.log("TaikoInbox deployed at:", address(taikoInbox));
        console.log("CheckpointTracker deployed at:", address(tracker));
        console.log("BlobRefRegistry address:", address(blobRefRegistry));
        console.log("SignalService address:", address(signalService));
        console.log("------------------------");


    }
}
