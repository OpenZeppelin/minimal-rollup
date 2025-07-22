// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedERC20} from "../../src/protocol/BridgedERC20.sol";
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
        IERC20Bridge.TokenInitialization memory tokenInit = IERC20Bridge.TokenInitialization({
            nonce: 0,
            originalToken: address(token),
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            sourceChain: 31337
        });
        
        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);
        
        // Prove initialization and deploy bridged token
        address deployedToken = bridge.proveTokenInitialization(tokenInit, height, proof);
        
        assertTrue(bridge.isInitializationProven(id));
        assertEq(bridge.getDeployedToken(address(token), 31337), deployedToken);
        
        // Check that the deployed token has correct metadata
        BridgedERC20 bridgedToken = BridgedERC20(deployedToken);
        assertEq(bridgedToken.name(), "Test Token");
        assertEq(bridgedToken.symbol(), "TEST");
        assertEq(bridgedToken.decimals(), 18);
        assertEq(bridgedToken.bridge(), address(bridge));
        assertEq(bridgedToken.originalToken(), address(token));
        assertEq(bridgedToken.sourceChain(), 31337);
    }

    function testCannotProveInitializationTwice() public {
        // First initialize
        vm.prank(alice);
        bridge.initializeToken(address(token));
        
        IERC20Bridge.TokenInitialization memory tokenInit = IERC20Bridge.TokenInitialization({
            nonce: 0,
            originalToken: address(token),
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            sourceChain: 31337
        });
        
        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);
        
        bridge.proveTokenInitialization(tokenInit, height, proof);
        
        vm.expectRevert(IERC20Bridge.InitializationAlreadyProven.selector);
        bridge.proveTokenInitialization(tokenInit, height, proof);
    }

    function testDeposit() public {
        // Initialize token first
        vm.prank(alice);
        bridge.initializeToken(address(token));
        
        vm.prank(alice);
        bridge.deposit(bob, address(token), 100, address(0));
        assertEq(token.balanceOf(address(bridge)), 100);
        assertEq(token.balanceOf(alice), 900);
    }

    function testCannotDepositUninitializedToken() public {
        vm.expectRevert(IERC20Bridge.TokenNotInitialized.selector);
        vm.prank(alice);
        bridge.deposit(bob, address(token), 100, address(0));
    }

    function testClaimDeposit() public {
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));
        
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), 100, address(0));

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            sourceChain: 31337,
            amount: 100,
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

    function testCancelDeposit() public {
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));
        
        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bytes32 id = bridge.deposit(bob, address(token), 100, canceler);

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            sourceChain: 31337,
            amount: 100,
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
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));
        
        address canceler = makeAddr("canceler");
        vm.prank(alice);
        bridge.deposit(bob, address(token), 100, canceler);

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            sourceChain: 31337,
            amount: 100,
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
        // Initialize token
        vm.prank(alice);
        bridge.initializeToken(address(token));
        
        vm.prank(alice);
        bridge.deposit(bob, address(token), 100, address(0));

        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: bob,
            localToken: address(token),
            sourceChain: 31337,
            amount: 100,
            canceler: address(0)
        });

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
        
        // Prove initialization on chain 2 (destination)
        IERC20Bridge.TokenInitialization memory tokenInit = IERC20Bridge.TokenInitialization({
            nonce: 0,
            originalToken: address(token),
            name: "Test Token",
            symbol: "TEST",
            decimals: 18,
            sourceChain: 31337
        });
        
        bytes memory proof = "mock_proof";
        uint256 height = 1;
        signalService.setVerifyResult(true);
        
        address bridgedToken = bridge2.proveTokenInitialization(tokenInit, height, proof);
        
        // Simulate bridging: deposit on chain 1, claim on chain 2
        vm.prank(alice);
        bytes32 depositId = bridge.deposit(alice, address(token), 200, address(0));
        
        IERC20Bridge.ERC20Deposit memory deposit = IERC20Bridge.ERC20Deposit({
            nonce: 0,
            from: alice,
            to: alice,
            localToken: address(token),
            sourceChain: 31337,
            amount: 200,
            canceler: address(0)
        });
        
        // Claim on chain 2 (mints bridged tokens)
        bridge2.claimDeposit(deposit, height, proof);
        
        // Now alice has bridged tokens on chain 2
        assertEq(BridgedERC20(bridgedToken).balanceOf(alice), 200);
        
        // Alice deposits bridged tokens back to chain 1
        vm.prank(alice);
        BridgedERC20(bridgedToken).approve(address(bridge2), 100);
        
        vm.prank(alice);
        bridge2.deposit(bob, bridgedToken, 100, address(0));
        
        // Bridged tokens should be burned (total supply decreases)
        assertEq(BridgedERC20(bridgedToken).balanceOf(alice), 100);
        assertEq(BridgedERC20(bridgedToken).totalSupply(), 100);
    }
}
