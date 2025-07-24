// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedERC1155} from "../../src/protocol/BridgedERC1155.sol";
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
        token.mint(alice, tokenId, 100, "");
        vm.prank(alice);
        token.setApprovalForAll(address(bridge), true);
    }

    function testInitializeToken() public {
        vm.prank(alice);
        bytes32 id = bridge.initializeToken(address(token));

        assertTrue(bridge.isTokenInitialized(address(token)));
        assertEq(signalService.lastSignalId(), id);
    }

    function testCannotInitializeTokenTwice() public {
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.expectRevert("Token already initialized");
        vm.prank(bob);
        bridge.initializeToken(address(token));
    }

    function testProveTokenInitialization() public {
        // First initialize on source chain
        vm.prank(alice);
        bytes32 id = bridge.initializeToken(address(token));

        // Prepare initialization data for destination chain
        IERC1155Bridge.TokenInitialization memory tokenInit = IERC1155Bridge.TokenInitialization({
            originalToken: address(token),
            uri: "https://example.com/metadata/0.json"
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        // Prove initialization and deploy bridged token
        address deployedToken = bridge.proveTokenInitialization(tokenInit, height, proof);

        assertTrue(bridge.isInitializationProven(id));
        assertEq(bridge.getDeployedToken(address(token)), deployedToken);

        // Check that the deployed token has correct metadata
        BridgedERC1155 bridgedToken = BridgedERC1155(deployedToken);
        assertEq(bridgedToken.owner(), address(bridge));
        assertEq(bridgedToken.originalToken(), address(token));
    }

    function testCannotProveInitializationTwice() public {
        // First initialize
        vm.prank(alice);
        bridge.initializeToken(address(token));

        IERC1155Bridge.TokenInitialization memory tokenInit = IERC1155Bridge.TokenInitialization({
            originalToken: address(token),
            uri: "https://example.com/metadata/0.json"
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.proveTokenInitialization(tokenInit, height, proof);

        vm.expectRevert(IERC1155Bridge.InitializationAlreadyProven.selector);
        bridge.proveTokenInitialization(tokenInit, height, proof);
    }

    function testDeposit() public {
        // Initialize token first
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), tokenId, 50, address(0));
        assertFalse(bridge.processed(id));
        assertEq(token.balanceOf(address(bridge), tokenId), 50);
        assertEq(token.balanceOf(alice, tokenId), 50);
    }

    function testCannotDepositUninitializedToken() public {
        vm.expectRevert(IERC1155Bridge.TokenNotInitialized.selector);
        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, 50, address(0));
    }

    function testClaimDeposit() public {
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), tokenId, 50, address(0));

        IERC1155Bridge.ERC1155Deposit memory deposit = IERC1155Bridge.ERC1155Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            amount: 50,
            tokenURI: "https://example.com/metadata/1.json",
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
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), tokenId, 50, canceler);

        IERC1155Bridge.ERC1155Deposit memory deposit = IERC1155Bridge.ERC1155Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            amount: 50,
            tokenURI: "https://example.com/metadata/1.json",
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

    function testCannotCancelIfNotCanceler() public {
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, 50, canceler);

        IERC1155Bridge.ERC1155Deposit memory deposit = IERC1155Bridge.ERC1155Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            amount: 50,
            tokenURI: "https://example.com/metadata/1.json",
            canceler: canceler
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        vm.expectRevert(IERC1155Bridge.OnlyCanceler.selector);
        vm.prank(address(0xBAD));
        bridge.cancelDeposit(deposit, alice, height, proof);
    }

    function testCannotClaimAlreadyClaimed() public {
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, 50, address(0));

        IERC1155Bridge.ERC1155Deposit memory deposit = IERC1155Bridge.ERC1155Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            amount: 50,
            tokenURI: "https://example.com/metadata/1.json",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        vm.expectRevert(IERC1155Bridge.AlreadyClaimed.selector);
        bridge.claimDeposit(deposit, height, proof);
    }

    function testCannotCancelAlreadyClaimed() public {
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, 50, canceler);

        IERC1155Bridge.ERC1155Deposit memory deposit = IERC1155Bridge.ERC1155Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            amount: 50,
            tokenURI: "https://example.com/metadata/1.json",
            canceler: canceler
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        vm.expectRevert(IERC1155Bridge.AlreadyClaimed.selector);
        vm.prank(canceler);
        bridge.cancelDeposit(deposit, alice, height, proof);
    }

    function testCannotCancelIfNoCanceler() public {
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, 50, address(0));

        IERC1155Bridge.ERC1155Deposit memory deposit = IERC1155Bridge.ERC1155Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            amount: 50,
            tokenURI: "https://example.com/metadata/1.json",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        vm.expectRevert(IERC1155Bridge.OnlyCanceler.selector);
        vm.prank(makeAddr("random"));
        bridge.cancelDeposit(deposit, alice, height, proof);
    }

    function testMetadataPropagation() public {
        // Create two separate bridge instances to simulate different chains
        ERC1155Bridge bridge2 = new ERC1155Bridge(address(signalService), trustedPublisher, counterpart);

        // Initialize token on chain 1
        vm.prank(alice);
        bridge.initializeToken(address(token));

        // Prove initialization on chain 2 (simulating it came from chain 1)
        IERC1155Bridge.TokenInitialization memory tokenInit = IERC1155Bridge.TokenInitialization({
            originalToken: address(token),
            uri: "https://example.com/metadata/0.json"
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        address bridgedToken = bridge2.proveTokenInitialization(tokenInit, height, proof);

        // Simulate bridging: deposit on chain 1, claim on chain 2
        vm.prank(alice);
        bridge.deposit(alice, address(token), tokenId, 25, address(0));

        // For the claim, simulate that this deposit came from chain 1
        IERC1155Bridge.ERC1155Deposit memory deposit = IERC1155Bridge.ERC1155Deposit({
            nonce: 0,
            from: alice,
            to: alice,
            localToken: address(token),
            tokenId: tokenId,
            amount: 25,
            tokenURI: "https://example.com/metadata/1.json",
            canceler: address(0)
        });

        // Claim on chain 2 (mints bridged token with metadata)
        bridge2.claimDeposit(deposit, height, proof);

        // Verify that the bridged token has the correct metadata
        BridgedERC1155 bridgedNFT = BridgedERC1155(bridgedToken);
        assertEq(bridgedNFT.balanceOf(alice, tokenId), 25);
        assertEq(bridgedNFT.uri(tokenId), "https://example.com/metadata/1.json");

        // Verify collection info is also correct
        assertEq(bridgedNFT.owner(), address(bridge2));
        assertEq(bridgedNFT.originalToken(), address(token));
    }
}
