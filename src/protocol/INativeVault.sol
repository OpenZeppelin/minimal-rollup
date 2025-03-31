// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title INativeVault
/// @notice Interface for the NativeVault contract.
interface INativeVault {
    /// @notice Emitted when a user's internal balance increases.
    event IncreaseBalance(address indexed user, uint256 amount);

    /// @notice Emitted when a user's internal balance is reduced.
    event ReduceBalance(address indexed user, uint256 amount);

    /// @notice Emitted when a deposit of native tokens is made.
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a withdrawal of native tokens is made.
    event Withdrawal(address indexed user, uint256 amount);

    /// @notice Error thrown when a user tries to withdraw more than their balance.
    error InsufficientBalance();

    /// @notice Deposit native currency (i.e. msg.value) into the contract.
    function deposit() external payable;

    /// @notice Withdraw native currency from the contract.
    /// @param amount The amount to withdraw.
    function withdraw(uint256 amount) external;

    /// @notice Returns the internal balance of a user.
    /// @param user The address of the user.
    /// @return The internal balance of the user.
    function balances(address user) external view returns (uint256);
}
