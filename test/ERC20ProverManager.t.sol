// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {BaseProverManager} from "../src/protocol/BaseProverManager.sol";
import {ERC20ProverManager} from "../src/protocol/ERC20ProverManager.sol";

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";
import {IPublicationFeed} from "src/protocol/IPublicationFeed.sol";
import {PublicationFeed} from "src/protocol/PublicationFeed.sol";

import {MockCheckpointTracker} from "test/mocks/MockCheckpointTracker.sol";

import {MockERC20} from "test/mocks/MockERC20.sol";
import {NullVerifier} from "test/mocks/NullVerifier.sol";

import {BaseProverManagerTest} from "./BaseProverManager.t.sol";
import {
    DELAYED_FEE_PERCENTAGE,
    EVICTOR_INCENTIVE_PERCENTAGE,
    EXIT_DELAY,
    INITIAL_FEE,
    INITIAL_PERIOD,
    LIVENESS_BOND,
    LIVENESS_WINDOW,
    MAX_BID_PERCENTAGE,
    PROVING_WINDOW,
    REWARD_PERCENTAGE,
    SUCCESSION_DELAY
} from "./BaseProverManager.t.sol";

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract ERC20ProverManagerMock is ERC20ProverManager {
    constructor(
        address _inbox,
        address _checkpointTracker,
        address _publicationFeed,
        address _initialProver,
        uint96 _initialFee,
        address _token,
        uint256 _initialDeposit
    )
        ERC20ProverManager(
            _inbox,
            _checkpointTracker,
            _publicationFeed,
            _initialProver,
            _initialFee,
            _token,
            _initialDeposit
        )
    {}

    function _maxBidPercentage() internal view virtual override returns (uint16) {
        return MAX_BID_PERCENTAGE;
    }

    function _livenessWindow() internal view virtual override returns (uint40) {
        return LIVENESS_WINDOW;
    }

    function _successionDelay() internal view virtual override returns (uint40) {
        return SUCCESSION_DELAY;
    }

    function _exitDelay() internal view virtual override returns (uint40) {
        return EXIT_DELAY;
    }

    function _provingWindow() internal view virtual override returns (uint40) {
        return PROVING_WINDOW;
    }

    function _livenessBond() internal view virtual override returns (uint96) {
        return LIVENESS_BOND;
    }

    function _evictorIncentivePercentage() internal view virtual override returns (uint16) {
        return EVICTOR_INCENTIVE_PERCENTAGE;
    }

    function _rewardPercentage() internal view virtual override returns (uint16) {
        return REWARD_PERCENTAGE;
    }

    function _delayedFeePercentage() internal view virtual override returns (uint16) {
        return DELAYED_FEE_PERCENTAGE;
    }
}

contract ERC20ProverManagerTest is BaseProverManagerTest {
    // Holds a reference to `proverManager` but with the type ERC20ProverManager to be
    // able to call functions that are specific to the ERC20ProverManager (i.e., `deposit`)
    ERC20ProverManager erc20ProverManager;

    MockERC20 mockToken;
    bytes32 constant SALT = "DEPLOY_SALT";

    function setUp() public override {
        super.setUp();

        // Create a new mock ERC20 token
        mockToken = new MockERC20();

        // Mint tokens to relevant addresses
        mockToken.mint(initialProver, LIVENESS_BOND + 10 ether);
        mockToken.mint(prover1, 10 ether);
        mockToken.mint(prover2, 10 ether);
        mockToken.mint(evictor, 10 ether);
        mockToken.mint(proposer, 10 ether);
        mockToken.mint(inbox, 10 ether);

        // Deploy the ERC20ProverManager to a deterministic address using CREATE2 and approve it to spend tokens from
        // the initial prover before deployment
        bytes memory args = abi.encode(
            inbox,
            address(checkpointTracker),
            address(publicationFeed),
            initialProver,
            INITIAL_FEE,
            address(mockToken),
            LIVENESS_BOND
        );
        address proverManagerAddress =
            vm.computeCreate2Address(SALT, hashInitCode(type(ERC20ProverManagerMock).creationCode, args));
        vm.prank(initialProver);
        mockToken.approve(proverManagerAddress, LIVENESS_BOND);

        // Create ProverManager instance
        proverManager = new ERC20ProverManagerMock{salt: SALT}(
            inbox,
            address(checkpointTracker),
            address(publicationFeed),
            initialProver,
            INITIAL_FEE,
            address(mockToken),
            LIVENESS_BOND
        );
        erc20ProverManager = ERC20ProverManager(address(proverManager));

        // Approve tokens for all test users
        vm.prank(initialProver);
        mockToken.approve(address(proverManager), type(uint256).max);

        vm.prank(prover1);
        mockToken.approve(address(proverManager), type(uint256).max);

        vm.prank(prover2);
        mockToken.approve(address(proverManager), type(uint256).max);

        vm.prank(evictor);
        mockToken.approve(address(proverManager), type(uint256).max);

        vm.prank(proposer);
        mockToken.approve(address(proverManager), type(uint256).max);

        vm.prank(inbox);
        mockToken.approve(address(proverManager), type(uint256).max);

        // Deposit enough as a proposer to pay for publications
        vm.prank(proposer);
        erc20ProverManager.deposit(INITIAL_FEE * 10);

        // Create a publication to trigger the new period
        vm.warp(vm.getBlockTimestamp() + 1);
        vm.prank(inbox);
        proverManager.payPublicationFee(proposer, false);
    }

    function test_setUp_TokenBalance() public view {
        // Test that the contract holds the correct amount of tokens after setup
        uint256 expectedBalance = LIVENESS_BOND + (INITIAL_FEE * 10); // Initial liveness bond + proposer deposit
        uint256 actualBalance = mockToken.balanceOf(address(proverManager));

        assertEq(actualBalance, expectedBalance, "Contract does not hold the correct token balance");
    }

    function test_Constructor_RevertWhen_ZeroTokenAddress() public {
        vm.expectRevert("Token address cannot be 0");
        new ERC20ProverManagerMock(
            inbox,
            address(checkpointTracker),
            address(publicationFeed),
            initialProver,
            INITIAL_FEE,
            address(0), // Zero address for token
            LIVENESS_BOND
        );
    }

    function test_deposit() public {
        vm.prank(prover1);
        vm.expectEmit();
        emit BaseProverManager.Deposit(prover1, DEPOSIT_AMOUNT);
        erc20ProverManager.deposit(DEPOSIT_AMOUNT);

        uint256 bal = proverManager.balances(prover1);
        assertEq(bal, DEPOSIT_AMOUNT, "Deposit did not update balance correctly");

        // Also check that the token was transferred from the user to the contract
        uint256 contractTokenBalance = mockToken.balanceOf(address(proverManager));
        assertEq(
            contractTokenBalance,
            LIVENESS_BOND + (INITIAL_FEE * 10) + DEPOSIT_AMOUNT,
            "Contract token balance not updated correctly"
        );
    }

    function test_deposit_RevertWhen_NotApproved() public {
        // Create a new address that hasn't approved tokens
        address newUser = address(0x999);
        mockToken.mint(newUser, DEPOSIT_AMOUNT);

        // Attempt to deposit without approving first
        vm.prank(newUser);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector, address(proverManager), 0, DEPOSIT_AMOUNT
            )
        );
        erc20ProverManager.deposit(DEPOSIT_AMOUNT);
    }

    function test_deposit_RevertWhen_InsufficientBalance() public {
        // Create a new address with insufficient token balance
        address poorUser = address(0x888);
        uint256 poorUserBalance = DEPOSIT_AMOUNT / 2;
        mockToken.mint(poorUser, poorUserBalance);

        vm.startPrank(poorUser);
        mockToken.approve(address(proverManager), DEPOSIT_AMOUNT);

        // Attempt to deposit more than the user has
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, poorUser, poorUserBalance, DEPOSIT_AMOUNT
            )
        );
        erc20ProverManager.deposit(DEPOSIT_AMOUNT);
    }

    function test_withdraw() public {
        uint256 withdrawAmount = 0.5 ether;
        _deposit(prover1, DEPOSIT_AMOUNT);

        // Get the token balance before withdrawal
        uint256 tokenBalanceBefore = mockToken.balanceOf(prover1);

        // Withdraw tokens
        vm.prank(prover1);
        vm.expectEmit();
        emit BaseProverManager.Withdrawal(prover1, withdrawAmount);
        proverManager.withdraw(withdrawAmount);

        // Get the token balance after withdrawal
        uint256 tokenBalanceAfter = mockToken.balanceOf(prover1);

        assertEq(
            proverManager.balances(prover1),
            DEPOSIT_AMOUNT - withdrawAmount,
            "Withdrawal did not update balance correctly"
        );

        assertEq(
            tokenBalanceAfter,
            tokenBalanceBefore + withdrawAmount,
            "Token balance did not increase by the correct amount"
        );
    }

    // -- HELPERS --
    function _deposit(address user, uint256 amount) internal override {
        vm.prank(user);
        erc20ProverManager.deposit(amount);
    }
}
