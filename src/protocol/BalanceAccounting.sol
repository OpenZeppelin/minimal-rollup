// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract BalanceAccounting {
    /// @notice Emitted when a user deposits into the contract
    /// @param user The address that made the deposit
    /// @param amount The amount that the user deposited
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws from the contract
    /// @param user The address that made the withdrawal
    /// @param amount The amount that the user withdrew
    event Withdrawal(address indexed user, uint256 amount);

    mapping(address user => uint256 balance) private _balances;

    /// @notice Withdraw available(unlocked) funds.
    /// @param amount The amount to withdraw
    function withdraw(uint256 amount) external {
        _decreaseBalance(msg.sender, amount);
        _transferOut(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    /// @dev Increases `user`'s balance by `amount` and emits a `Deposit` event
    function _deposit(address user, uint256 amount) internal {
        _increaseBalance(user, amount);
        emit Deposit(user, amount);
    }

    /// @dev Implements currency-specific transfer logic for withdrawals
    function _transferOut(address to, uint256 amount) internal virtual;

    /// @notice Get the balance of a user
    /// @param user The address of the user
    /// @return The balance of the user
    function balances(address user) public view returns (uint256) {
        return _balances[user];
    }

    function _increaseBalance(address user, uint256 amount) internal {
        _balances[user] += amount;
    }

    function _decreaseBalance(address user, uint256 amount) internal {
        _balances[user] -= amount;
    }
}
