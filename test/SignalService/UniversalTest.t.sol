// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {InitialState} from "./InitialState.t.sol";
import {ICommitmentStore} from "src/protocol/ICommitmentStore.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

/// This contract describes behaviours that should be valid in every state
/// It can be inherited by any Test contract to run all tests in that state
abstract contract UniversalTest is InitialState {
    address commitmentPublisher = _randomAddress("commitmentPublisher");
    address alice = _randomAddress("alice");
    address bob = _randomAddress("bob");

    function test_storeCommitment_heightIsZero() public {
        bytes32 commitment = keccak256(abi.encodePacked("arbitrary_commitment"));
        uint256 height = 0;

        bytes32 stored = signalService.commitmentAt(commitmentPublisher, height);
        assertEq(stored, bytes32(0), "commitment already stored");

        vm.prank(commitmentPublisher);
        vm.expectEmit();
        emit ICommitmentStore.CommitmentStored(commitmentPublisher, height, commitment);
        signalService.storeCommitment(height, commitment);

        stored = signalService.commitmentAt(commitmentPublisher, height);
        assertEq(stored, commitment, "commitment not stored");
    }

    function test_storeCommitment_heightIsTen() public {
        bytes32 commitment = keccak256(abi.encodePacked("arbitrary_commitment"));
        uint256 height = 10;

        bytes32 stored = signalService.commitmentAt(commitmentPublisher, height);
        assertEq(stored, bytes32(0), "commitment already stored");

        vm.prank(commitmentPublisher);
        vm.expectEmit();
        emit ICommitmentStore.CommitmentStored(commitmentPublisher, height, commitment);
        signalService.storeCommitment(height, commitment);

        stored = signalService.commitmentAt(commitmentPublisher, height);
        assertEq(stored, commitment, "commitment not stored");
    }

    function test_sendSignal_valueIsZero() public {
        bytes32 value = bytes32(0);

        bool stored = signalService.isSignalStored(value, alice);
        assertFalse(stored, "signal already stored");

        vm.prank(alice);
        vm.expectEmit();
        emit ISignalService.SignalSent(alice, value);
        signalService.sendSignal(value);

        stored = signalService.isSignalStored(value, alice);
        assertTrue(stored, "signal not stored");
    }

    function test_sendSignal_valueIsNonZero() public {
        bytes32 value = keccak256("arbitrary_signal");

        bool stored = signalService.isSignalStored(value, alice);
        assertFalse(stored, "signal already stored");

        vm.prank(alice);
        vm.expectEmit();
        emit ISignalService.SignalSent(alice, value);
        signalService.sendSignal(value);

        stored = signalService.isSignalStored(value, alice);
        assertTrue(stored, "signal not stored");
    }

    function test_sendSignal_differentValuesDifferentSlots() public {
        bytes32[] memory values = new bytes32[](2);
        values[0] = keccak256("arbitrary_signal_0");
        values[0] = keccak256("arbitrary_signal_1");

        bytes32[] memory slots = new bytes32[](2);
        vm.startPrank(alice);
        slots[0] = signalService.sendSignal(values[0]);
        slots[1] = signalService.sendSignal(values[1]);
        vm.stopPrank();

        assertNotEq(slots[0], slots[1], "different signals are stored in same slot");
    }

    function test_sendSignal_differentCallersDifferentSlots() public {
        bytes32 value = keccak256("arbitrary_signal");

        bytes32 slotAlice;
        bytes32 slotBob;

        vm.prank(alice);
        slotAlice = signalService.sendSignal(value);

        vm.prank(bob);
        slotBob = signalService.sendSignal(value);

        assertNotEq(slotAlice, slotBob, "different callers use same slot");
    }
}
