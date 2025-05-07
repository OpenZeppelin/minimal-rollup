// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";

import {ISignaler} from "../../src/protocol/fabric/ISignaler.sol";
import {Signaler} from "../../src/protocol/fabric/Signaler.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract DumbOracle {
    uint256 private _price;

    function setPrice(uint256 price_) external returns (uint256) {
        _price = price_;
        return _price;
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }
}

contract MockSignalService {
    bytes32 private _signal;

    function sendSignal(bytes32 signal_) external returns (bytes32 slot) {
        _signal = signal_;
        return bytes32("0x1337");
    }

    function getSignal() external view returns (bytes32) {
        return _signal;
    }
}

/**
 * @title SignalerTest
 * @dev Test contract for Signaler functionality
 */
contract SignalerTest is Test {
    address public signalService;
    address alice;
    uint256 alicePrivateKey;
    uint256 aliceInitialBalance;
    address bob;
    uint256 bobPrivateKey;
    uint256 bobInitialBalance;

    function setUp() public {
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");
        aliceInitialBalance = 100 ether;
        bobInitialBalance = 100 ether;
        vm.deal(alice, aliceInitialBalance);
        vm.deal(bob, bobInitialBalance);

        // Create a mock SignalService instance
        signalService = address(new MockSignalService());
        console.log("signalService address", signalService);

        // Create the Signaler instance
        Signaler _signaler = new Signaler();
        console.log("signaler address", address(_signaler));

        // Alice uses the Signaler as her 7702 account
        vm.signAndAttachDelegation(address(_signaler), alicePrivateKey);
        vm.signAndAttachDelegation(address(_signaler), bobPrivateKey);

        // Set the SignalService address
        vm.prank(alice);
        ISignaler(address(alice)).setSignalService(signalService);
        vm.prank(bob);
        ISignaler(address(bob)).setSignalService(signalService);
    }

    /**
     * @dev Helper function to encode multiple calls into a single bytes array
     * @param calls Array of calls to encode
     * @return Encoded bytes representation of the calls
     */
    function encodeCalls(ISignaler.Call[] memory calls) internal returns (bytes memory) {
        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }
        return encodedCalls;
    }

    /**
     * @dev Helper function to sign a batch of calls
     * @param privateKey The private key of the signer
     * @param calls The calls to sign
     * @param nonce The nonce of the signer
     * @return signature The signed batch of calls
     */
    function signBatch(uint256 privateKey, ISignaler.Call[] memory calls, uint256 nonce)
        internal
        returns (bytes memory signature)
    {
        bytes memory encodedCalls = encodeCalls(calls);
        bytes32 digest = keccak256(abi.encodePacked(nonce, encodedCalls));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, MessageHashUtils.toEthSignedMessageHash(digest));
        signature = abi.encodePacked(r, s, v);
    }

    /**
     * @dev Test basic contract deployment with 7702
     */
    function test_deploy() public {
        require(address(alice).code.length != 0);
        require(ISignaler(address(alice)).nonce() == 0, "interface works");
        require(ISignaler(address(alice)).signalService() == signalService, "signalService is set");
        require(address(bob).code.length != 0, "interface works");
        require(ISignaler(address(bob)).nonce() == 0, "interface works");
        require(ISignaler(address(bob)).signalService() == signalService, "signalService is set");
    }

    /**
     * @dev Test basic ETH transfer functionality works despite 7702
     */
    function test_basicTransfer() public {
        vm.prank(alice);
        (bool success,) = bob.call{value: 1 ether}("");
        require(success, "transfer failed");
        assertEq(bob.balance, bobInitialBalance + 1 ether);
        assertEq(alice.balance, aliceInitialBalance - 1 ether);
    }

    /**
     * @dev Test batch ETH transfers initiated by the owner
     */
    function test_executeBatch() public {
        // Alice pre-signs an ETH transfer to Bob
        address dest1 = makeAddr("dest1");
        address dest2 = makeAddr("dest2");
        ISignaler.Call[] memory calls = new ISignaler.Call[](2);
        calls[0] = ISignaler.Call({to: dest1, value: 1 ether, data: "", batcher: alice});
        calls[1] = ISignaler.Call({to: dest2, value: 1 ether, data: "", batcher: alice});

        // Alice submits the call
        vm.prank(alice);
        ISignaler(address(alice)).executeBatch(calls);

        // Verify the transfer was executed
        assertEq(dest1.balance, 1 ether);
        assertEq(dest2.balance, 1 ether);
    }

    /**
     * @dev Test batch ETH transfer functionality using executeBatchWithSig, submitted by a non-owner
     */
    function test_executeBatchWithSig() public {
        address dest1 = makeAddr("dest1");
        address dest2 = makeAddr("dest2");

        // Create two transfer calls
        ISignaler.Call[] memory calls = new ISignaler.Call[](2);
        calls[0] = ISignaler.Call({to: dest1, value: 1 ether, data: "", batcher: bob});
        calls[1] = ISignaler.Call({to: dest2, value: 1 ether, data: "", batcher: bob});

        // Encode and sign the batch
        bytes memory signature = signBatch(alicePrivateKey, calls, ISignaler(address(alice)).nonce());

        // Execute the batch
        vm.prank(bob); // bob executes on behalf of alice
        ISignaler(address(alice)).executeBatchWithSig(calls, signature);

        // Verify balances
        assertEq(dest1.balance, 1 ether);
        assertEq(dest2.balance, 1 ether);
    }

    /**
     * @dev Test batch ETH transfer functionality using executeBatchWithSig, submitted by the owner
     */
    function test_executeBatchWithSig_batcherMismatch() public {
        address batcher = makeAddr("batcher");

        // Create a transfer call
        ISignaler.Call[] memory calls = new ISignaler.Call[](1);
        calls[0] = ISignaler.Call({to: batcher, value: 1 ether, data: "", batcher: batcher});

        // Encode and sign the batch
        bytes memory signature = signBatch(alicePrivateKey, calls, ISignaler(address(alice)).nonce());

        // Execute the batch
        vm.prank(bob); // bob executes instead of batcher
        vm.expectRevert(ISignaler.BatcherMismatch.selector);
        ISignaler(address(alice)).executeBatchWithSig(calls, signature);
    }

    /**
     * @dev Test executeBatchWithSig reverts if a call is unbatched
     */
    function test_executeBatchWithSig_invalidSignature() public {
        address dest1 = makeAddr("dest1");
        address dest2 = makeAddr("dest2");

        // Create two transfer calls
        ISignaler.Call[] memory calls = new ISignaler.Call[](2);
        calls[0] = ISignaler.Call({to: dest1, value: 1 ether, data: "", batcher: bob});
        calls[1] = ISignaler.Call({to: dest2, value: 1 ether, data: "", batcher: bob});

        // Encode and sign the batch
        bytes memory signature = signBatch(alicePrivateKey, calls, ISignaler(address(alice)).nonce());

        // Attempt to unbatch the 2nd call
        ISignaler.Call[] memory calls2 = new ISignaler.Call[](1);
        calls2[0] = calls[0];

        // Execute the batch
        vm.prank(bob); // bob executes on behalf of alice
        vm.expectRevert(ISignaler.InvalidSignature.selector);
        ISignaler(address(alice)).executeBatchWithSig(calls2, signature);
    }

    /**
     * @dev Test a nested batch of calls, assuming all accounts are Signalers
     */
    function test_nestedBatchExecuteWithSig() public {
        // Charlie is the end recipient of the eth transfers
        address charlie = makeAddr("charlie");

        // Bob pre-signs an ETH transfer to Charlie
        ISignaler.Call[] memory subCalls = new ISignaler.Call[](1);
        subCalls[0] = ISignaler.Call({
            to: charlie,
            value: 1 ether,
            data: "",
            batcher: alice // this call is nested in Alice's batch
        });
        bytes memory subSignature = signBatch(bobPrivateKey, subCalls, ISignaler(address(bob)).nonce());

        // Verify this call cannot be sent as a standalone batch
        vm.prank(bob);
        vm.expectRevert(ISignaler.BatcherMismatch.selector);
        ISignaler(address(bob)).executeBatchWithSig(subCalls, subSignature);

        // Encode Bob's eth transfer as an executeBatch() call that will be executed in Alice's batch
        ISignaler.Call[] memory calls = new ISignaler.Call[](2);
        calls[0] = ISignaler.Call({
            to: bob,
            value: 0,
            data: abi.encodeCall(ISignaler.executeBatchWithSig, (subCalls, subSignature)),
            batcher: alice // alice will submit her own batch
        });

        calls[1] = ISignaler.Call({
            to: charlie,
            value: 1 ether,
            data: "",
            batcher: alice // alice will submit her own batch
        });

        // Execute the batch (no signature required since Alice is the submitter)
        vm.prank(alice);
        ISignaler(address(alice)).executeBatch(calls);

        // Verify the transfer was executed
        assertEq(alice.balance, aliceInitialBalance - 1 ether);
        assertEq(bob.balance, bobInitialBalance - 1 ether);
        assertEq(charlie.balance, 2 ether);
    }

    /**
     * @dev Test that a signal is sent when a call is executed
     */
    function test_sendSignal() public {
        // Create a new DumbOracle instance
        DumbOracle oracle = new DumbOracle();
        uint256 price = 42;

        // Create the call
        ISignaler.Call[] memory calls = new ISignaler.Call[](1);
        calls[0] = ISignaler.Call({
            to: address(oracle),
            value: 0,
            data: abi.encodeWithSelector(DumbOracle.setPrice.selector, price),
            batcher: bob
        });

        // Encode and sign the batch
        bytes memory signature = signBatch(alicePrivateKey, calls, ISignaler(address(alice)).nonce());

        // Delegate batch execution using a signature
        vm.prank(bob); // not owner
        ISignaler(address(alice)).executeBatchWithSig(calls, signature);

        // Verify the price was set
        assertEq(oracle.getPrice(), price, "price was not set");

        // Verify the right signal was sent
        bytes32 gotSignal = MockSignalService(signalService).getSignal();
        bytes32 expectedSignal = keccak256(abi.encode(calls[0], abi.encode(price)));
        assertEq(gotSignal, expectedSignal, "signal was not sent");
    }
}
