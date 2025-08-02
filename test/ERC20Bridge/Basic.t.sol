// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedERC20} from "../../src/protocol/BridgedERC20.sol";
import "forge-std/Test.sol";
import {ERC20Bridge} from "src/protocol/ERC20Bridge.sol";
import {IERC20Bridge} from "src/protocol/IERC20Bridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

import {MockBrokenERC20} from "test/mocks/MockBrokenERC20.sol";
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
    }

    function testInitializeToken() public {
        vm.prank(alice);
        bytes32 id = bridge.initializeToken(address(token));

        assertEq(signalService.lastSignalId(), id);
    }

    function testDeployCounterpartToken() public {
        // First initialize on source chain
        vm.prank(alice);
        bytes32 id = bridge.recordTokenDescription(address(token));

        // Prepare initialization data for destination chain
        IERC20Bridge.TokenDescription memory tokenDesc = IERC20Bridge.TokenDescription({
            originalToken: address(token),
            name: "Test Token",
            symbol: "TEST",
            decimals: 18
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        // Prove initialization and deploy bridged token
        address deployedToken = bridge.deployCounterpartToken(tokenDesc, height, proof);

        assertTrue(bridge.processed(id));
        assertEq(bridge.getDeployedToken(address(token)), deployedToken);

        // Check that the deployed token has correct metadata
        BridgedERC20 bridgedToken = BridgedERC20(deployedToken);
        assertEq(bridgedToken.name(), "Test Token");
        assertEq(bridgedToken.symbol(), "TEST");
        assertEq(bridgedToken.decimals(), 18);
        assertEq(bridgedToken.owner(), address(bridge));
        assertEq(bridgedToken.originalToken(), address(token));
    }

    function testCannotProveInitializationTwice() public {
        // First initialize
        vm.prank(alice);
        bridge.initializeToken(address(token));

        IERC20Bridge.TokenDescription memory tokenDesc = IERC20Bridge.TokenDescription({
            originalToken: address(token),
            name: "Test Token",
            symbol: "TEST",
            decimals: 18
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.deployCounterpartToken(tokenDesc, height, proof);

        vm.expectRevert(IERC20Bridge.CounterpartTokenAlreadyDeployed.selector);
        bridge.deployCounterpartToken(tokenDesc, height, proof);
    }

    function testDeposit() public {
        // Initialize token first
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bridge.deposit(bob, address(token), 100);
        assertEq(token.balanceOf(address(bridge)), 100);
        assertEq(token.balanceOf(alice), 900);
    }

    function testClaimDeposit() public {
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), 100);

        IERC20Bridge.ERC20Deposit memory deposit =
            IERC20Bridge.ERC20Deposit({nonce: 0, from: alice, to: bob, originalToken: address(token), amount: 100});

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        assertTrue(bridge.processed(id));
        assertEq(token.balanceOf(bob), 100);
        assertEq(token.balanceOf(address(bridge)), 0);
    }

    function testCannotClaimAlreadyClaimed() public {
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));

        vm.prank(alice);
        bridge.deposit(bob, address(token), 100);

        IERC20Bridge.ERC20Deposit memory deposit =
            IERC20Bridge.ERC20Deposit({nonce: 0, from: alice, to: bob, originalToken: address(token), amount: 100});

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        bridge.claimDeposit(deposit, height, proof);

        vm.expectRevert(IERC20Bridge.AlreadyClaimed.selector);
        bridge.claimDeposit(deposit, height, proof);
    }

    function testBridgedTokenDeposit() public {
        // Create two separate bridge instances to simulate different chains
        ERC20Bridge bridge2 = new ERC20Bridge(address(signalService), trustedPublisher, counterpart);

        // Initialize token on chain 1
        vm.prank(alice);
        bridge.initializeToken(address(token));

        // Prove initialization on chain 2 (simulating it came from chain 1)
        IERC20Bridge.TokenDescription memory tokenDesc = IERC20Bridge.TokenDescription({
            originalToken: address(token),
            name: "Test Token",
            symbol: "TEST",
            decimals: 18
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        address bridgedToken = bridge2.deployCounterpartToken(tokenDesc, height, proof);

        // Simulate bridging: deposit on chain 1, claim on chain 2
        vm.prank(alice);
        bytes32 depositId = bridge.deposit(alice, address(token), 200);

        // For the claim, simulate that this deposit came from chain 1
        IERC20Bridge.ERC20Deposit memory deposit =
            IERC20Bridge.ERC20Deposit({nonce: 0, from: alice, to: alice, originalToken: address(token), amount: 200});

        // Claim on chain 2 (mints bridged tokens)
        bridge2.claimDeposit(deposit, height, proof);

        // Now alice has bridged tokens on chain 2
        assertEq(BridgedERC20(bridgedToken).balanceOf(alice), 200);

        // Alice deposits bridged tokens back to chain 1
        vm.prank(alice);
        BridgedERC20(bridgedToken).approve(address(bridge2), 100);

        vm.prank(alice);
        bridge2.deposit(bob, bridgedToken, 100);

        // Bridged tokens should be burned (total supply decreases)
        assertEq(BridgedERC20(bridgedToken).balanceOf(alice), 100);
        assertEq(BridgedERC20(bridgedToken).totalSupply(), 100);
    }

    function testBrokenTokenMetadata() public {
        // Deploy a broken token that reverts on metadata calls
        MockBrokenERC20 brokenToken = new MockBrokenERC20();

        // Initialize should work with fallback values
        vm.prank(alice);
        bytes32 id = bridge.initializeToken(address(brokenToken));

        // Token initialization completed

        // Get the initialization to check fallback values were used
        IERC20Bridge.TokenDescription memory tokenDesc = IERC20Bridge.TokenDescription({
            originalToken: address(brokenToken),
            name: "Unknown Token Name", // Should use fallback
            symbol: "UNKNOWN", // Should use fallback
            decimals: 18 // Should use fallback
        });

        bytes32 expectedId = bridge.getTokenDescriptionId(tokenDesc);
        assertEq(id, expectedId);

        // Should be able to prove initialization with fallback values
        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        address deployedToken = bridge.deployCounterpartToken(tokenDesc, height, proof);

        // Verify the bridged token was deployed with fallback metadata
        assertEq(BridgedERC20(deployedToken).name(), "Unknown Token Name");
        assertEq(BridgedERC20(deployedToken).symbol(), "UNKNOWN");
        assertEq(BridgedERC20(deployedToken).decimals(), 18);
    }

    function testSignalIDDifferentiation() public {
        // Deploy and initialize token
        vm.prank(alice);
        bytes32 initId = bridge.initializeToken(address(token));

        // Create a deposit (alice already has tokens and approval from setUp)
        vm.prank(alice);
        bytes32 depositId = bridge.deposit(alice, address(token), 100);

        // Verify the signal IDs are different
        assertNotEq(initId, depositId, "Initialization and deposit IDs should be different");

        // Verify the IDs are deterministic (same inputs = same outputs)
        IERC20Bridge.TokenDescription memory tokenDesc = IERC20Bridge.TokenDescription({
            originalToken: address(token),
            name: "Test Token",
            symbol: "TEST",
            decimals: 18
        });
        bytes32 expectedInitId = bridge.getTokenDescriptionId(tokenDesc);
        assertEq(initId, expectedInitId, "Initialization ID should be deterministic");
    }

    function testBridgedTokenBaseFeatures() public {
        // Initialize and prove token initialization
        MockERC20 originalToken = new MockERC20("Original Token", "ORIG");
        bridge.initializeToken(address(originalToken));

        IERC20Bridge.TokenDescription memory tokenDesc = IERC20Bridge.TokenDescription({
            originalToken: address(originalToken),
            name: "Original Token",
            symbol: "ORIG",
            decimals: 18
        });

        signalService.setVerifyResult(true);
        address bridgedTokenAddr = bridge.deployCounterpartToken(tokenDesc, 1, new bytes(0));
        BridgedERC20 bridgedToken = BridgedERC20(bridgedTokenAddr);

        // Test originalToken tracking
        assertEq(bridgedToken.originalToken(), address(originalToken), "originalToken should be tracked");

        // Test ownership (bridge is the owner)
        assertEq(bridgedToken.owner(), address(bridge), "Bridge should be the owner");

        // Test that only owner (bridge) can mint
        vm.expectRevert(); // Should revert with OwnableUnauthorizedAccount
        bridgedToken.mint(alice, 100);

        // Bridge (owner) should be able to mint
        vm.prank(address(bridge));
        bridgedToken.mint(alice, 100);
        assertEq(bridgedToken.balanceOf(alice), 100, "Alice should have 100 tokens");
    }

    function testCannotDeployDuplicateBridgedToken() public {
        // First, deploy a bridged token successfully
        IERC20Bridge.TokenDescription memory tokenDesc1 = IERC20Bridge.TokenDescription({
            originalToken: address(token),
            name: "Test Token",
            symbol: "TEST",
            decimals: 18
        });

        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);

        // First deployment should succeed
        address bridgedToken = bridge.deployCounterpartToken(tokenDesc1, height, proof);
        assertNotEq(bridgedToken, address(0), "First deployment should succeed");

        // Try to deploy again with different metadata but same original token
        // This should be caught by our new validation
        IERC20Bridge.TokenDescription memory tokenDesc2 = IERC20Bridge.TokenDescription({
            originalToken: address(token), // Same original token
            name: "Different Token Name", // Different metadata
            symbol: "DIFF",
            decimals: 6
        });

        signalService.setVerifyResult(true); // Reset for the second call
        vm.expectRevert("Counterpart token already exists for this original token");
        bridge.deployCounterpartToken(tokenDesc2, height, proof);
    }
}
