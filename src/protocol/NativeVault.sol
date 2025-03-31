// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {INativeVault} from "./INativeVault.sol";

/// @dev A contract that handles accounting for native tokens.
///
/// Offers an simple interface to handle internal accounting of deposited native tokens.
/// Native tokens are deposited calling the `deposit` function, and can be withdrawn using the `withdraw` function.
///
/// It is recommended to use this contract as a base for applications that require isolated accounting of native tokens.
/// Example use cases include stake, liveness bonds, or any other economic mechanism that require native tokens.
/// to be deposited and withdrawn.
abstract contract NativeVault is INativeVault {
    mapping(address user => uint256 balance) private _balances;

    /// @inheritdoc INativeVault
    function deposit() external payable virtual {
        _increaseBalance(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /// @inheritdoc INativeVault
    function withdraw(uint256 amount) external virtual {
        _reduceBalance(msg.sender, amount);

        address to = msg.sender;
        bool ok;
        // Using assembly to avoid memory allocation costs; only the call's success matters to ensure funds are sent.
        assembly ("memory-safe") {
            ok := call(gas(), to, amount, 0, 0, 0, 0)
        }
        require(ok, "NativeVault: transfer failed");
        emit Withdrawal(to, amount);
    }

    /// @inheritdoc INativeVault
    function balances(address user) external view virtual returns (uint256) {
        return _balances[user];
    }

    /// @notice Reduce the balance of a user.
    function _reduceBalance(address user, uint256 amount) internal virtual {
        if (_balances[user] < amount) {
            revert InsufficientBalance();
        }
        _balances[user] -= amount;
        emit ReduceBalance(user, amount);
    }

    /// @notice Increase the balance of a user.
    function _increaseBalance(address user, uint256 amount) internal virtual {
        _balances[user] += amount;
        emit IncreaseBalance(user, amount);
    }
}
