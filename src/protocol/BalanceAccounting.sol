// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract BalanceAccounting {
    mapping(address user => uint256 balance) private _balances;

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
