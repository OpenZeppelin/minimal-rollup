// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {InitialState} from "./InitialState.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

/// Test contract for cancelDeposit functionality with data parameter
contract CancelDepositTest is InitialState {
    uint256 HEIGHT = 1;
    
    address alice = _randomAddress("alice");
    address bob = _randomAddress("bob");
    address charlie = _randomAddress("charlie");
    address canceler = _randomAddress("canceler");
    
    function setUp() public override {
        super.setUp();
        vm.deal(alice, 10 ether);
    }

    function test_cancelDeposit_withEmptyData() public {
        // Create a cancellable deposit
        vm.prank(alice);
        bytes32 depositId = bridge.deposit{value: 1 ether}(bob, "original_data", "", canceler);
        
        // Get the deposit details
        IETHBridge.ETHDeposit memory ethDeposit = IETHBridge.ETHDeposit({
            nonce: 0,
            from: alice,
            to: bob,
            amount: 1 ether,
            data: "original_data",
            context: "",
            canceler: canceler
        });
        
        // Mock the signal service to allow cancellation
        vm.mockCall(
            address(signalService),
            abi.encodeWithSelector(signalService.verifySignal.selector),
            abi.encode(true)
        );
        
        uint256 charlieBalanceBefore = charlie.balance;
        
        // Cancel the deposit with empty data
        vm.prank(canceler);
        bridge.cancelDeposit(ethDeposit, charlie, "", HEIGHT, "proof");
        
        // Verify the deposit was cancelled and ETH sent to claimee
        assertTrue(bridge.processed(depositId), "Deposit should be marked as processed");
        assertEq(charlie.balance, charlieBalanceBefore + 1 ether, "Charlie should receive the ETH");
    }

    function test_cancelDeposit_withCustomData() public {
        // Create a cancellable deposit
        vm.prank(alice);
        bytes32 depositId = bridge.deposit{value: 1 ether}(bob, "original_data", "", canceler);
        
        // Get the deposit details
        IETHBridge.ETHDeposit memory ethDeposit = IETHBridge.ETHDeposit({
            nonce: 0,
            from: alice,
            to: bob,
            amount: 1 ether,
            data: "original_data",
            context: "",
            canceler: canceler
        });
        
        // Mock the signal service to allow cancellation
        vm.mockCall(
            address(signalService),
            abi.encodeWithSelector(signalService.verifySignal.selector),
            abi.encode(true)
        );
        
        uint256 charlieBalanceBefore = charlie.balance;
        
        // Cancel the deposit with custom data
        bytes memory cancelData = "cancel_data_payload";
        vm.prank(canceler);
        bridge.cancelDeposit(ethDeposit, charlie, cancelData, HEIGHT, "proof");
        
        // Verify the deposit was cancelled and ETH sent to claimee
        assertTrue(bridge.processed(depositId), "Deposit should be marked as processed");
        assertEq(charlie.balance, charlieBalanceBefore + 1 ether, "Charlie should receive the ETH");
    }

    function test_cancelDeposit_shouldRevertIfNotCanceler() public {
        // Create a cancellable deposit
        vm.prank(alice);
        bridge.deposit{value: 1 ether}(bob, "original_data", "", canceler);
        
        // Get the deposit details
        IETHBridge.ETHDeposit memory ethDeposit = IETHBridge.ETHDeposit({
            nonce: 0,
            from: alice,
            to: bob,
            amount: 1 ether,
            data: "original_data",
            context: "",
            canceler: canceler
        });
        
        // Try to cancel from a different address
        vm.prank(alice); // Not the canceler
        vm.expectRevert(IETHBridge.OnlyCanceler.selector);
        bridge.cancelDeposit(ethDeposit, charlie, "some_data", HEIGHT, "proof");
    }

    function test_cancelDeposit_shouldEmitEvent() public {
        // Create a cancellable deposit
        vm.prank(alice);
        bytes32 depositId = bridge.deposit{value: 1 ether}(bob, "original_data", "", canceler);
        
        // Get the deposit details
        IETHBridge.ETHDeposit memory ethDeposit = IETHBridge.ETHDeposit({
            nonce: 0,
            from: alice,
            to: bob,
            amount: 1 ether,
            data: "original_data",
            context: "",
            canceler: canceler
        });
        
        // Mock the signal service to allow cancellation
        vm.mockCall(
            address(signalService),
            abi.encodeWithSelector(signalService.verifySignal.selector),
            abi.encode(true)
        );
        
        // Expect the DepositCancelled event
        vm.expectEmit();
        emit IETHBridge.DepositCancelled(depositId, charlie);
        
        // Cancel the deposit
        vm.prank(canceler);
        bridge.cancelDeposit(ethDeposit, charlie, "cancel_data", HEIGHT, "proof");
    }

    function test_cancelDeposit_shouldRevertIfAlreadyProcessed() public {
        // Create a cancellable deposit
        vm.prank(alice);
        bytes32 depositId = bridge.deposit{value: 1 ether}(bob, "original_data", "", canceler);
        
        // Get the deposit details
        IETHBridge.ETHDeposit memory ethDeposit = IETHBridge.ETHDeposit({
            nonce: 0,
            from: alice,
            to: bob,
            amount: 1 ether,
            data: "original_data",
            context: "",
            canceler: canceler
        });
        
        // Mock the signal service to allow cancellation
        vm.mockCall(
            address(signalService),
            abi.encodeWithSelector(signalService.verifySignal.selector),
            abi.encode(true)
        );
        
        // Cancel the deposit first time
        vm.prank(canceler);
        bridge.cancelDeposit(ethDeposit, charlie, "cancel_data", HEIGHT, "proof");
        
        // Verify it's processed
        assertTrue(bridge.processed(depositId), "Deposit should be marked as processed");
        
        // Try to cancel again - should revert
        vm.prank(canceler);
        vm.expectRevert(IETHBridge.AlreadyClaimed.selector);
        bridge.cancelDeposit(ethDeposit, charlie, "cancel_data", HEIGHT, "proof");
    }

    function test_cancelDeposit_shouldCallClaimeeWithData() public {
        // Deploy a mock contract to receive the cancelled deposit
        MockReceiver mockReceiver = new MockReceiver();
        
        // Create a cancellable deposit
        vm.prank(alice);
        bytes32 depositId = bridge.deposit{value: 1 ether}(bob, "original_data", "", canceler);
        
        // Get the deposit details
        IETHBridge.ETHDeposit memory ethDeposit = IETHBridge.ETHDeposit({
            nonce: 0,
            from: alice,
            to: bob,
            amount: 1 ether,
            data: "original_data",
            context: "",
            canceler: canceler
        });
        
        // Mock the signal service to allow cancellation
        vm.mockCall(
            address(signalService),
            abi.encodeWithSelector(signalService.verifySignal.selector),
            abi.encode(true)
        );
        
        // Cancel the deposit with custom data to the mock receiver
        bytes memory cancelData = abi.encodeWithSignature("onCancelReceived(bytes32)", depositId);
        vm.prank(canceler);
        bridge.cancelDeposit(ethDeposit, address(mockReceiver), cancelData, HEIGHT, "proof");
        
        // Verify the mock receiver was called with the expected data
        assertTrue(mockReceiver.wasCalledWithData(), "Mock receiver should have been called with data");
        assertEq(mockReceiver.receivedDepositId(), depositId, "Mock receiver should have received correct deposit ID");
    }
}

/// Mock contract to test contract calls during cancellation
contract MockReceiver {
    bool public wasCalledWithData;
    bytes32 public receivedDepositId;
    
    function onCancelReceived(bytes32 depositId) external payable {
        wasCalledWithData = true;
        receivedDepositId = depositId;
    }
    
    // Fallback to receive ETH
    receive() external payable {}
} 