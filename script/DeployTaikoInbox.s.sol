// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BlobRefRegistry} from "../src/blobs/BlobRefRegistry.sol";
import {IBlobRefRegistry} from "../src/blobs/IBlobRefRegistry.sol";
import {ILookahead} from "../src/protocol/ILookahead.sol";
import {IProposerFees} from "../src/protocol/IProposerFees.sol";
import {TaikoInbox} from "../src/protocol/taiko_alethia/TaikoInbox.sol";

import {MockProposerFees} from "./MockProposerFee.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/// @title DeployTaikoInbox
/// @notice Script to deploy the TaikoInbox contract
contract DeployTaikoInbox is Script {
    // Default values that can be overridden via environment variables
    address private lookaheadAddr;
    address private blobRefRegistryAddr;
    uint256 private maxAnchorBlockIdOffset;
    address private proposerFeesAddr;
    uint256 private inclusionDelay;

    function setUp() public {
        // Deploy MockProposerFees contract
        MockProposerFees mockProposerFees = new MockProposerFees();
        BlobRefRegistry blobRefRegistry = new BlobRefRegistry();
        // Load values from environment variables or use defaults
        lookaheadAddr = vm.envOr("LOOKAHEAD_ADDRESS", address(0));
        blobRefRegistryAddr = address(blobRefRegistry);
        maxAnchorBlockIdOffset = vm.envOr("MAX_ANCHOR_BLOCK_ID_OFFSET", uint256(256));
        proposerFeesAddr = address(mockProposerFees);
        inclusionDelay = vm.envOr("INCLUSION_DELAY", uint256(3600)); // Default: 1 hour
    }

    function run() public returns (TaikoInbox) {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy TaikoInbox contract
        TaikoInbox taikoInbox =
            new TaikoInbox(lookaheadAddr, blobRefRegistryAddr, maxAnchorBlockIdOffset, proposerFeesAddr, inclusionDelay);

        // Stop broadcasting
        vm.stopBroadcast();

        // Log deployment information
        console.log("TaikoInbox deployed at:", address(taikoInbox));
        console.log("Lookahead address:", lookaheadAddr);
        console.log("BlobRefRegistry address:", blobRefRegistryAddr);
        console.log("Max anchor block ID offset:", maxAnchorBlockIdOffset);
        console.log("ProposerFees address:", proposerFeesAddr);
        console.log("Inclusion delay:", inclusionDelay);

        return taikoInbox;
    }
}
