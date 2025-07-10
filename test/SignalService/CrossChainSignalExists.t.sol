// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SampleProof} from "./SampleProof.t.sol";
import {UniversalTest} from "./UniversalTest.t.sol";

import {LibSignal} from "src/libs/LibSignal.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

/// This contract describes behaviours that should be valid when a cross chain signal exists.
/// This implies a signal was sent on another chain and the commitment was stored on this chain.
/// We use the SampleProof contract to track the signal details.
contract CrossChainSignalExists is UniversalTest {
    uint256 HEIGHT = 1;

    function setUp() public override {
        super.setUp();
        ISignalService.SignalProof memory signalProof = sampleProof.getSignalProof();
        bytes32 commitment = keccak256(abi.encodePacked(signalProof.stateRoot, signalProof.blockHash));
        vm.prank(commitmentPublisher);
        signalService.storeCommitment(HEIGHT, commitment);
    }

    // This is just a sanity-check.
    // It does not test any contract behaviour but just validates consistency with the sample proof
    function test_expectedSlot() public view {
        (address sender, bytes32 value) = sampleProof.getSignalDetails();
        bytes32 expectedSlot = LibSignal.deriveSlot(value, sender);
        bytes32 actualSlot = sampleProof.getSlot();
        assertEq(actualSlot, expectedSlot, "slot mismatch");
    }

    function test_verifySignal_shouldSucceed() public {
        (address sender, bytes32 value) = sampleProof.getSignalDetails();
        ISignalService.SignalProof memory signalProof = sampleProof.getSignalProof();
        bytes memory proof = abi.encode(signalProof);

        vm.expectEmit();
        emit ISignalService.SignalVerified(sender, value);
        signalService.verifySignal(HEIGHT, commitmentPublisher, sender, value, proof);
    }
}
