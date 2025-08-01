// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedERC721} from "../../src/protocol/BridgedERC721.sol";
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
    }

    function testInitializeToken() public {
        vm.prank(alice);
        bytes32 id = bridge.initializeToken(address(token));

        assertEq(signalService.lastSignalId(), id);
    }

    function testDeployCounterpartToken() public {
        // First initialize on source chain
        vm.prank(alice);
        bytes32 id = bridge.initializeToken(address(token));

        // Prepare initialization data for destination chain
        IERC721Bridge.TokenInitialization memory tokenInit =
            IERC721Bridge.TokenInitialization({originalToken: address(token), name: "Test NFT", symbol: "TNFT"});

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        // Prove initialization and deploy bridged token
        address deployedToken = bridge.deployCounterpartToken(tokenInit, height, proof);

        assertTrue(bridge.isInitializationProven(id));
        assertEq(bridge.getDeployedToken(address(token)), deployedToken);

        // Check that the deployed token has correct metadata
        BridgedERC721 bridgedToken = BridgedERC721(deployedToken);
        assertEq(bridgedToken.name(), "Test NFT");
        assertEq(bridgedToken.symbol(), "TNFT");
        assertEq(bridgedToken.owner(), address(bridge));
        assertEq(bridgedToken.originalToken(), address(token));
    }

    function testCannotProveInitializationTwice() public {
        // First initialize
        vm.prank(alice);
        bridge.initializeToken(address(token));

        IERC721Bridge.TokenInitialization memory tokenInit =
            IERC721Bridge.TokenInitialization({originalToken: address(token), name: "Test NFT", symbol: "TNFT"});

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.deployCounterpartToken(tokenInit, height, proof);

        vm.expectRevert(IERC721Bridge.InitializationAlreadyProven.selector);
        bridge.deployCounterpartToken(tokenInit, height, proof);
    }

    function testDeposit() public {
        // Initialize token first
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, address(0));
        assertEq(token.ownerOf(tokenId), address(bridge));
    }

    function testClaimDeposit() public {
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), tokenId, address(0));

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            tokenURI: "https://example.com/metadata/1",
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
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), tokenId, canceler);

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            tokenURI: "https://example.com/metadata/1",
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
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, canceler);

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            tokenURI: "https://example.com/metadata/1",
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
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, address(0));

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            tokenURI: "https://example.com/metadata/1",
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
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, canceler);

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            tokenURI: "https://example.com/metadata/1",
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
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bridge.deposit(bob, address(token), tokenId, address(0));

        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            tokenId: tokenId,
            tokenURI: "https://example.com/metadata/1",
            canceler: address(0)
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        vm.expectRevert(IERC721Bridge.OnlyCanceler.selector);
        vm.prank(makeAddr("random"));
        bridge.cancelDeposit(deposit, alice, height, proof);
    }

    function testBridgedTokenDeposit() public {
        // Create two separate bridge instances to simulate different chains
        ERC721Bridge bridge2 = new ERC721Bridge(address(signalService), trustedPublisher, counterpart);

        // Initialize token on chain 1
        vm.prank(alice);
        bridge.initializeToken(address(token));

        // Prove initialization on chain 2 (simulating it came from chain 1)
        IERC721Bridge.TokenInitialization memory tokenInit =
            IERC721Bridge.TokenInitialization({originalToken: address(token), name: "Test NFT", symbol: "TNFT"});

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        address bridgedToken = bridge2.deployCounterpartToken(tokenInit, height, proof);

        // Simulate bridging: deposit on chain 1, claim on chain 2
        vm.prank(alice);
        bytes32 depositId = bridge.deposit(alice, address(token), tokenId, address(0));

        // For the claim, simulate that this deposit came from chain 1
        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: alice,
            localToken: address(token),
            tokenId: tokenId,
            tokenURI: "https://example.com/metadata/1",
            canceler: address(0)
        });

        // Claim on chain 2 (mints bridged token)
        bridge2.claimDeposit(deposit, height, proof);

        // Now alice has bridged token on chain 2
        assertEq(BridgedERC721(bridgedToken).ownerOf(tokenId), alice);

        // Alice deposits bridged token back to chain 1
        vm.prank(alice);
        BridgedERC721(bridgedToken).approve(address(bridge2), tokenId);

        vm.prank(alice);
        bridge2.deposit(bob, bridgedToken, tokenId, address(0));

        // Bridged token should be burned (no longer exists)
        vm.expectRevert();
        BridgedERC721(bridgedToken).ownerOf(tokenId);
    }

    function testMetadataPropagation() public {
        // Create two separate bridge instances to simulate different chains
        ERC721Bridge bridge2 = new ERC721Bridge(address(signalService), trustedPublisher, counterpart);

        // Initialize token on chain 1
        vm.prank(alice);
        bridge.initializeToken(address(token));

        // Prove initialization on chain 2 (simulating it came from chain 1)
        IERC721Bridge.TokenInitialization memory tokenInit =
            IERC721Bridge.TokenInitialization({originalToken: address(token), name: "Test NFT", symbol: "TNFT"});

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        address bridgedToken = bridge2.deployCounterpartToken(tokenInit, height, proof);

        // Simulate bridging: deposit on chain 1, claim on chain 2
        vm.prank(alice);
        bridge.deposit(alice, address(token), tokenId, address(0));

        // For the claim, simulate that this deposit came from chain 1
        IERC721Bridge.ERC721Deposit memory deposit = IERC721Bridge.ERC721Deposit({
            nonce: 0,
            from: alice,
            to: alice,
            localToken: address(token),
            tokenId: tokenId,
            tokenURI: "https://example.com/metadata/1",
            canceler: address(0)
        });

        // Claim on chain 2 (mints bridged token with metadata)
        bridge2.claimDeposit(deposit, height, proof);

        // Verify that the bridged token has the correct metadata
        BridgedERC721 bridgedNFT = BridgedERC721(bridgedToken);
        assertEq(bridgedNFT.ownerOf(tokenId), alice);
        assertEq(bridgedNFT.tokenURI(tokenId), "https://example.com/metadata/1");

        // Verify collection metadata is also correct
        assertEq(bridgedNFT.name(), "Test NFT");
        assertEq(bridgedNFT.symbol(), "TNFT");
    }
}
