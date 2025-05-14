// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SampleDepositProof} from "./SampleDepositProof.t.sol";
import {UniversalTest} from "./UniversalTest.t.sol";

import {LibSignal} from "src/libs/LibSignal.sol";

import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

/// This contract describes behaviours that should be valid when a cross chain deposit exists.
/// This implies a deposit was made on the counterpart bridge (on another chain) and the commitment
/// was stored on this chain's signal service.
/// We use the SampleDepositProof contract to track the deposit details.
contract CrossChainDepositExists is UniversalTest {
    // the sample deposit is to this address
    address recipient = _randomAddress("recipient");

    uint256 HEIGHT = 1;

    function setUp() public override {
        super.setUp();
        ISignalService.SignalProof memory signalProof = sampleDepositProof.getDepositSignalProof();
        bytes32 commitment = keccak256(abi.encodePacked(signalProof.stateRoot, signalProof.blockHash));
        vm.prank(trustedCommitmentPublisher);
        signalService.storeCommitment(HEIGHT, commitment);
    }

    // This is just a sanity-check.
    // It does not test any contract behaviour but just validates consistency with the sample proof
    function test_depositInternals() public view {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit();
        (bytes32 slot, bytes32 id) = sampleDepositProof.getDepositInternals();

        assertEq(bridge.getDepositId(deposit), id, "deposit id mismatch");
        assertEq(LibSignal.deriveSlot(id, counterpart), slot, "slot mismatch");
    }

    function test_claimDeposit_shouldSucceed() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit();
        ISignalService.SignalProof memory signalProof = sampleDepositProof.getDepositSignalProof();
        bytes memory proof = abi.encode(signalProof);

        bridge.claimDeposit(deposit, HEIGHT, proof);
    }
}
