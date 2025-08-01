// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

/// This contract describes behaviours that should be valid in every state
/// It can be inherited by any Test contract to run all tests in that state
abstract contract UniversalTest is InitialState {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");

    function setUp() public virtual override {
        super.setUp();

        vm.deal(alice, 10 ether);
    }

    // This is not testing contract functionality.
    // Rather, it validates a behaviour that we rely on in subsequent tests.
    function test_deposit_snapshotAllowsReproducibleDeposit() public {
        uint256 snapshotId = vm.snapshot();

        vm.prank(alice);
        bytes32 id0 = bridge.deposit(charlie, "", anyRelayer, nonCancellableAddress);

        vm.revertTo(snapshotId);

        vm.prank(alice);
        bytes32 id1 = bridge.deposit(charlie, "", anyRelayer, nonCancellableAddress);

        assertEq(id0, id1, "identical deposits produce different ids");
    }

    function test_deposit_differentCallerProducesDifferentId() public {
        uint256 snapshotId = vm.snapshot();

        vm.prank(alice);
        bytes32 id0 = bridge.deposit(charlie, "", anyRelayer, nonCancellableAddress);

        vm.revertTo(snapshotId);

        vm.prank(bob);
        bytes32 id1 = bridge.deposit(charlie, "", anyRelayer, nonCancellableAddress);

        assertNotEq(id0, id1, "different caller produces same id");
    }

    function test_deposit_differentRecipientProducesDifferentId() public {
        vm.startPrank(alice);

        uint256 snapshotId = vm.snapshot();

        bytes32 id0 = bridge.deposit(bob, "", anyRelayer, nonCancellableAddress);

        vm.revertTo(snapshotId);

        bytes32 id1 = bridge.deposit(charlie, "", anyRelayer, nonCancellableAddress);

        assertNotEq(id0, id1, "different recipient produces same id");
    }

    function test_deposit_differentValueProducesDifferentId() public {
        vm.startPrank(alice);

        uint256 snapshotId = vm.snapshot();

        bytes32 id0 = bridge.deposit{value: 0.5 ether}(bob, "", anyRelayer, nonCancellableAddress);

        vm.revertTo(snapshotId);

        bytes32 id1 = bridge.deposit{value: 1 ether}(bob, "", anyRelayer, nonCancellableAddress);

        assertNotEq(id0, id1, "different value produces same id");
    }

    function test_deposit_differentDataProducesDifferentId() public {
        vm.startPrank(alice);

        uint256 snapshotId = vm.snapshot();

        bytes32 id0 = bridge.deposit(bob, "", anyRelayer, nonCancellableAddress);

        vm.revertTo(snapshotId);

        bytes32 id1 = bridge.deposit(bob, "somedata", anyRelayer, nonCancellableAddress);

        assertNotEq(id0, id1, "different value produces same id");
    }

    function test_deposit_incrementsNonce() public {
        uint256 initialNonce = getNonce();

        vm.startPrank(alice);
        bridge.deposit(bob, "", anyRelayer, nonCancellableAddress);

        assertEq(getNonce(), initialNonce + 1, "nonce not incremented");
    }

    function test_deposit_duplicateDepositsProduceDifferentIds() public {
        vm.startPrank(alice);

        bytes32 id0 = bridge.deposit(bob, "", anyRelayer, nonCancellableAddress);
        bytes32 id1 = bridge.deposit(bob, "", anyRelayer, nonCancellableAddress);

        assertNotEq(id0, id1, "duplicate deposits produce same id");
    }

    function test_deposit_idMatchesGetterFunction() public {
        IETHBridge.ETHDeposit memory ethDeposit = IETHBridge.ETHDeposit({
            nonce: getNonce(),
            from: alice,
            to: bob,
            amount: 1 ether,
            data: "",
            context: anyRelayer,
            canceler: nonCancellableAddress
        });

        vm.prank(ethDeposit.from);
        bytes32 id =
            bridge.deposit{value: ethDeposit.amount}(ethDeposit.to, ethDeposit.data, anyRelayer, nonCancellableAddress);

        assertEq(id, bridge.getDepositId(ethDeposit), "id does not match getter");
    }

    function test_deposit_DepositMadeEvent() public {
        IETHBridge.ETHDeposit memory ethDeposit = IETHBridge.ETHDeposit({
            nonce: getNonce(),
            from: alice,
            to: bob,
            amount: 1 ether,
            data: "",
            context: anyRelayer,
            canceler: nonCancellableAddress
        });
        bytes32 id = bridge.getDepositId(ethDeposit);

        vm.prank(ethDeposit.from);
        vm.expectEmit();
        emit IETHBridge.DepositMade(id, ethDeposit);
        bridge.deposit{value: ethDeposit.amount}(ethDeposit.to, ethDeposit.data, anyRelayer, nonCancellableAddress);
    }

    function test_deposit_signalNotSavedUnderCaller() public {
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, "", anyRelayer, nonCancellableAddress);

        assertFalse(signalService.isSignalStored(id, alice), "signal saved under caller");
    }

    function test_deposit_signalNotSavedUnderRecipient() public {
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, "", anyRelayer, nonCancellableAddress);

        assertFalse(signalService.isSignalStored(id, bob), "signal saved under recipient");
    }

    function test_deposit_signalSavedUnderBridge() public {
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, "", anyRelayer, nonCancellableAddress);

        assertTrue(signalService.isSignalStored(id, address(bridge)), "signal not saved");
    }

    function test_deposit_ETHTransferred() public {
        uint256 initialAliceBalance = alice.balance;
        uint256 initialBobBalance = bob.balance;
        uint256 initialBridgeBalance = address(bridge).balance;
        uint256 amount = 1 ether;

        vm.prank(alice);
        bridge.deposit{value: amount}(bob, "", anyRelayer, nonCancellableAddress);

        assertEq(alice.balance, initialAliceBalance - amount, "source balance mismatch");
        assertEq(bob.balance, initialBobBalance, "recipient balance changed");
        assertEq(address(bridge).balance, initialBridgeBalance + amount, "bridge balance mismatch");
    }
}
