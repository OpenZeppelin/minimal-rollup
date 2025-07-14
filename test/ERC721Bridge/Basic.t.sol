// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {ERC721Bridge} from "src/protocol/ERC721Bridge.sol";
import {IERC721Bridge} from "src/protocol/IERC721Bridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";
import {MockERC721} from "test/mocks/MockERC721.sol";
import {MockSignalService} from "test/mocks/MockSignalService.sol";

contract ERC721BridgeTest is Test {
    ERC721Bridge bridge;
    MockSignalService signalService;
    MockERC721 token;
    address trustedPublisher = address(0x123);
    address counterpart = address(0x456);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    uint256 tokenId = 1;

    function setUp() public {
        signalService = new MockSignalService();
        bridge = new ERC721Bridge(address(signalService), trustedPublisher, counterpart);
        token = new MockERC721("Test NFT", "TNFT");
        token.mint(alice, tokenId);
        vm.prank(alice);
        token.approve(address(bridge), tokenId);
        bridge.setTokenMapping(address(token), address(token), false);
    }

    // solhint-disable no-unused-vars
    function testDeposit() public {
        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, "", "", address(0));
        assertEq(token.ownerOf(tokenId), address(bridge));
    }

    function testClaimDeposit() public {
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), tokenId, "", "", address(0));

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            remoteToken: address(token),
            tokenId: tokenId,
            data: "",
            context: "",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        assertTrue(bridge.processed(id));
        assertEq(token.ownerOf(tokenId), bob);
    }

    function testCancelDeposit() public {
        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), tokenId, "", "", canceler);

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            remoteToken: address(token),
            tokenId: tokenId,
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
        assertEq(token.ownerOf(tokenId), alice);
    }

    function testCannotCancelIfNotCanceler() public {
        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, "", "", canceler);

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            remoteToken: address(token),
            tokenId: tokenId,
            data: "",
            context: "",
            canceler: canceler
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        vm.expectRevert(IERC721Bridge.OnlyCanceler.selector);
        vm.prank(address(0xBAD));
        bridge.cancelDeposit(deposit, alice, height, proof);
    }

    function testCannotClaimAlreadyClaimed() public {
        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, "", "", address(0));

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            remoteToken: address(token),
            tokenId: tokenId,
            data: "",
            context: "",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        vm.expectRevert(IERC721Bridge.AlreadyClaimed.selector);
        bridge.claimDeposit(deposit, height, proof);
    }

    function testCannotCancelAlreadyClaimed() public {
        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, "", "", canceler);

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            remoteToken: address(token),
            tokenId: tokenId,
            data: "",
            context: "",
            canceler: canceler
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        vm.expectRevert(IERC721Bridge.AlreadyClaimed.selector);
        vm.prank(canceler);
        bridge.cancelDeposit(deposit, alice, height, proof);
    }

    function testCannotCancelIfNoCanceler() public {
        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, "", "", address(0));

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            remoteToken: address(token),
            tokenId: tokenId,
            data: "",
            context: "",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        vm.expectRevert(IERC721Bridge.OnlyCanceler.selector);
        vm.prank(makeAddr("random"));
        bridge.cancelDeposit(deposit, alice, height, proof);
    }
}
