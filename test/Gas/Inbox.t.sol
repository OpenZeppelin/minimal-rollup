// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BlobRefRegistry} from "../../src/blobs/BlobRefRegistry.sol";
import {IBlobRefRegistry} from "../../src/blobs/IBlobRefRegistry.sol";
import {CheckpointTracker} from "../../src/protocol/CheckpointTracker.sol";

import {ILookahead} from "../../src/protocol/ILookahead.sol";
import {IProposerFees} from "../../src/protocol/IProposerFees.sol";
import {TaikoInbox} from "../../src/protocol/taiko_alethia/TaikoInbox.sol";

import {MockVerifier} from "../mocks/MockVerifier.sol";
import {SignalService} from "src/protocol/SignalService.sol";

import {MockProposerFees} from "./MockProposerFee.sol";
import {Script} from "forge-std/Test.sol";

/// @title DeployTaikoInbox
/// @notice Script to deploy the TaikoInbox contract
contract DeployTaikoInbox is Test {
    // Default values that can be overridden via environment variables
    address private lookaheadAddr;
    uint256 private maxAnchorBlockIdOffset;
    uint256 private inclusionDelay;

    function setUp() public {
        lookaheadAddr = address(0);
        maxAnchorBlockIdOffset = uint256(100);
        inclusionDelay = uint256(3600);
    }

    function setup() public returns (TaikoInbox) {
        MockProposerFees mockProposerFees = new MockProposerFees();
        BlobRefRegistry blobRefRegistry = new BlobRefRegistry();
        TaikoInbox taikoInbox = new TaikoInbox(
            lookaheadAddr, address(blobRefRegistry), maxAnchorBlockIdOffset, address(mockProposerFees), inclusionDelay
        );

        MockVerifier verifier = new MockVerifier();

        SignalService signalService = new SignalService();

        address proverManager = address(0);

        CheckpointTracker tracker = new CheckpointTracker(
            keccak256(abi.encode("genesis")),
            address(taikoInbox),
            address(verifier),
            proverManager,
            address(signalService)
        );

        taikoInbox.publish(1, 550);
        uint256[] memory blobIndices = new uint256[](2);
        blobIndices[0] = 0;
        blobIndices[1] = 1;
        blobRefRegistry.registerRef(blobIndices);
    }
}
