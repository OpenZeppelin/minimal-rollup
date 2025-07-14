// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IMintableERC20} from "../../src/protocol/IMintable.sol";
import "forge-std/Test.sol";
import {ERC20Bridge} from "src/protocol/ERC20Bridge.sol";
import {IERC20Bridge} from "src/protocol/IERC20Bridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {MockSignalService} from "test/mocks/MockSignalService.sol";

contract ERC20BridgeTest is Test {
    ERC20Bridge bridge;
    MockSignalService signalService;
    MockERC20 token;
    address trustedPublisher = address(0x123);
    address counterpart = address(0x456);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        signalService = new MockSignalService();
        bridge = new ERC20Bridge(address(signalService), trustedPublisher, counterpart);
        token = new MockERC20("Test Token", "TEST");
        token.mint(alice, 1000);
        vm.prank(alice);
        token.approve(address(bridge), type(uint256).max);
        bridge.setTokenMapping(address(token), address(token), false);
    }

    // solhint-disable no-unused-vars
    function testDeposit() public {
        vm.prank(alice);
        bridge.deposit(bob, address(token), 100, "", "", address(0));
        assertEq(token.balanceOf(address(bridge)), 100);
        assertEq(token.balanceOf(alice), 900);
    }

    function testDepositMintable() public {
        bridge.setTokenMapping(address(token), address(token), true);
        vm.prank(alice);
        vm.expectCall(address(token), abi.encodeCall(IMintableERC20.burn, (address(bridge), 100)));
        bridge.deposit(bob, address(token), 100, "", "", address(0));
        assertEq(token.balanceOf(alice), 900);
    }

    function testClaimDeposit() public {
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), 100, "", "", address(0));

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            token: address(token),
            amount: 100,
            data: "",
            context: "",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        assertTrue(bridge.processed(id));
        assertEq(token.balanceOf(bob), 100);
        assertEq(token.balanceOf(address(bridge)), 0);
    }

    function testClaimMintable() public {
        bridge.setTokenMapping(address(token), address(token), true);
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), 100, "", "", address(0));

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            token: address(token),
            amount: 100,
            data: "",
            context: "",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        vm.expectCall(address(token), abi.encodeCall(IMintableERC20.mint, (bob, 100)));
        bridge.claimDeposit(deposit, height, proof);

        assertTrue(bridge.processed(id));
        assertEq(token.balanceOf(bob), 100);
    }

    function testCancelDeposit() public {
        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), 100, "", "", canceler);

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            token: address(token),
            amount: 100,
            data: "",
            context: "",
            canceler: canceler
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        vm.prank(canceler);
        bridge.cancelDeposit(deposit, alice, height, proof);

        assertTrue(bridge.processed(id));
        assertEq(token.balanceOf(alice), 1000); // back to original
        assertEq(token.balanceOf(address(bridge)), 0);
    }

    function testCannotCancelIfNotCanceler() public {
        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bridge.deposit(bob, address(token), 100, "", "", canceler);

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            token: address(token),
            amount: 100,
            data: "",
            context: "",
            canceler: canceler
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        vm.expectRevert(IERC20Bridge.OnlyCanceler.selector);
        vm.prank(address(0xBAD));
        bridge.cancelDeposit(deposit, alice, height, proof);
    }

    function testCannotClaimAlreadyClaimed() public {
        vm.prank(alice);
        bridge.deposit(bob, address(token), 100, "", "", address(0));

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            token: address(token),
            amount: 100,
            data: "",
            context: "",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        vm.expectRevert(IERC20Bridge.AlreadyClaimed.selector);
        bridge.claimDeposit(deposit, height, proof);
    }

    function testCannotCancelAlreadyClaimed() public {
        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bridge.deposit(bob, address(token), 100, "", "", canceler);

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            token: address(token),
            amount: 100,
            data: "",
            context: "",
            canceler: canceler
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        vm.expectRevert(IERC20Bridge.AlreadyClaimed.selector);
        vm.prank(canceler);
        bridge.cancelDeposit(deposit, alice, height, proof);
    }

    function testCannotCancelIfNoCanceler() public {
        vm.prank(alice);
        bridge.deposit(bob, address(token), 100, "", "", address(0));

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            token: address(token),
            amount: 100,
            data: "",
            context: "",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        vm.expectRevert(IERC20Bridge.OnlyCanceler.selector);
        vm.prank(makeAddr("random"));
        bridge.cancelDeposit(deposit, alice, height, proof);
    }

    function testUnsupportedToken() public {
        vm.expectRevert("Unsupported token");
        vm.prank(alice);
        bridge.deposit(bob, address(0xBAD), 100, "", "", address(0));
    }
}
