// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {L1Rollup} from "../L1Rollup.sol";

/// @dev An {L1Rollup} with support for internal ETH accounting.
abstract contract L1RollupDepositable is L1Rollup {
    event IncreaseBalance(address indexed user, uint256 amount);
    event ReduceBalance(address indexed user, uint256 amount);

    error InsufficientBalance();

    mapping(address user => uint256 balance) private _balances;

    /// @notice Deposit ETH into the contract. The deposit can be used both for opting in as a prover.
    function deposit() external payable virtual {
        _increaseBalance(msg.sender, msg.value);
    }

    /// @notice Withdraw available (unlocked) funds.
    function withdraw(uint256 amount) external virtual {
        _reduceBalance(msg.sender, amount);

        address to = msg.sender;
        bool ok;
        // Using assembly to avoid memory allocation costs; only the call's success matters to ensure funds are sent.
        assembly ("memory-safe") {
            ok := call(gas(), to, amount, 0, 0, 0, 0)
        }

        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Common balances for proposers and provers
    function balances(address user) external view virtual returns (uint256) {
        return _balances[user];
    }

    /// @notice Withdraw ETH from the contract
    function _reduceBalance(address user, uint256 amount) internal virtual {
        if (_balances[user] < amount) {
            revert InsufficientBalance();
        }
        _balances[user] -= amount;
        emit ReduceBalance(user, amount);
    }

    /// @notice Increase the balance of a user
    function _increaseBalance(address user, uint256 amount) internal virtual {
        _balances[user] += amount;
        emit IncreaseBalance(user, amount);
    }
}
