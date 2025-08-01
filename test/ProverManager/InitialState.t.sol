// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {MockCheckpointTracker} from "../mocks/MockCheckpointTracker.sol";
import {MockInbox} from "../mocks/MockInbox.sol";
import {BaseProverManager} from "src/protocol/BaseProverManager.sol";

abstract contract InitialState is Test {
    BaseProverManager proverManager;
    MockInbox inbox;
    MockCheckpointTracker checkpointTracker;

    address deployer = makeAddr("deployer");
    address initialProver = makeAddr("initialProver");
    address proposer = makeAddr("proposer");
    address proverA = makeAddr("proverA");
    address proverB = makeAddr("proverB");
    address evictor = makeAddr("evictor");

    // Configuration parameters.
    uint96 initialFee = 0.1 ether;
    uint256 initialDeposit = 1.5 ether; // more than the liveness bond
    uint256 constant DEPOSIT_AMOUNT = 2 ether;
    uint256 constant WITHDRAW_AMOUNT = 0.5 ether;

    function setUp() public virtual {
        inbox = new MockInbox();
        checkpointTracker = new MockCheckpointTracker();
        proverManager = _createProverManager();
        _prefund(proposer, 10 ether);
        _prefund(initialProver, 10 ether);
        _prefund(proverA, 10 ether);
        _prefund(proverB, 10 ether);
        _prefund(evictor, 10 ether);
    }

    function _createProverManager() internal virtual returns (BaseProverManager);

    function _prefund(address account, uint256 amount) internal virtual;

    // this will be overridden in the token scenario to create the approval
    // note: we split this functionality from _executeDeposit so we can isolate the
    // deposit call when using the vm.expectEmit instrumentation
    function _prepareForDeposit(address depositor, uint256 amount) internal virtual;

    function _executeDeposit(address depositor, uint256 amount) internal virtual;

    function _deposit(address depositor, uint256 amount) internal {
        _prepareForDeposit(depositor, amount);
        _executeDeposit(depositor, amount);
    }

    function _currencyBalance(address account) internal view virtual returns (uint256);
}
