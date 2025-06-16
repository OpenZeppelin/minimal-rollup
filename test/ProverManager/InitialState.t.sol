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

    address deployer = _randomAddress("deployer");
    address initialProver = _randomAddress("initialProver");
    uint96 initialFee = 0.1 ether;
    uint256 initialDeposit = 1.5 ether; // more than the liveness bond

    function setUp() public virtual {
        inbox = new MockInbox();
        checkpointTracker = new MockCheckpointTracker();
        proverManager = _createProverManager();
    }

    function _createProverManager() internal virtual returns (BaseProverManager);

    function _randomAddress(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encode(_domainSeparator(), name)))));
    }

    function _domainSeparator() internal pure returns (bytes32) {
        return keccak256("ProverManager");
    }
}
