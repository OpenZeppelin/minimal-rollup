// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BaseProverManager} from "./BaseProverManager.sol";
import {IETHDepositor} from "./IProverManager.sol";

/// @title ETHProverManager
/// @notice Implementation of the `BaseProverManager` contract that uses ETH for bids, stake and paying for publication
/// fees.
abstract contract ETHProverManager is BaseProverManager, IETHDepositor {
    constructor(
        address _inbox,
        address _checkpointTracker,
        address _publicationFeed,
        address _initialProver,
        uint96 _initialFee
    ) payable BaseProverManager(_inbox, _checkpointTracker, _publicationFeed, _initialProver, _initialFee, msg.value) {
        require(
            msg.value >= _livenessBond(),
            "The amount of ETH deposited must be greater than or equal to the livenessBond"
        );
    }

    /// @notice Receive ETH transfers and deposit them to the sender's balance
    /// @dev This allows direct ETH transfers to the contract to be credited as deposits
    receive() external payable {
        _deposit(msg.sender, msg.value);
    }

    /// @inheritdoc IETHDepositor
    /// @dev The deposit can be used both for opting in as a prover or proposer
    function deposit() external payable {
        _deposit(msg.sender, msg.value);
    }

    function _transferOut(address to, uint256 amount) internal override {
        bool ok;
        // Using assembly to avoid memory allocation costs; only the call's success matters to ensure funds are sent.
        assembly ("memory-safe") {
            ok := call(gas(), to, amount, 0, 0, 0, 0)
        }
        require(ok, "Withdraw failed");
    }
}
