// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import {ERC1155Bridge} from "src/protocol/ERC1155Bridge.sol";
import {IERC1155Bridge} from "src/protocol/IERC1155Bridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";
import {MockERC1155} from "test/mocks/MockERC1155.sol";
import {MockSignalService} from "test/mocks/MockSignalService.sol";

contract ERC1155BridgeTest is Test {
    ERC1155Bridge bridge;
    MockSignalService signalService;
    MockERC1155 token;
    address trustedPublisher = address(0x123);
    address counterpart = address(0x456);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    uint256 tokenId = 1;

    function setUp() public {
        signalService = new MockSignalService();
        bridge = new ERC1155Bridge(address(signalService), trustedPublisher, counterpart);
        token = new MockERC1155();
        token.mint(alice, tokenId, 100);
        vm.prank(alice);
        token.setApprovalForAll(address(bridge), true);
    }

    function testDeposit() public {
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), tokenId, 50, "", "", address(0));
        assertEq(token.balanceOf(address(bridge), tokenId), 50);
        assertEq(token.balanceOf(alice, tokenId), 50);
    }

    function testClaimDeposit() public {
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), tokenId, 50, "", "", address(0));

        IERC1155Bridge.ERC1155Deposit memory deposit = IERC1155Bridge.ERC1155Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            token: address(token),
            tokenId: tokenId,
            amount: 50,
            data: "",
            context: "",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        assertTrue(bridge.processed(id));
        assertEq(token.balanceOf(bob, tokenId), 50);
        assertEq(token.balanceOf(address(bridge), tokenId), 0);
    }

    function testCancelDeposit() public {
        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), tokenId, 50, "", "", canceler);

        IERC1155Bridge.ERC1155Deposit memory deposit = IERC1155Bridge.ERC1155Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            token: address(token),
            tokenId: tokenId,
            amount: 50,
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
        assertEq(token.balanceOf(alice, tokenId), 100); // back to original
        assertEq(token.balanceOf(address(bridge), tokenId), 0);
    }
} 