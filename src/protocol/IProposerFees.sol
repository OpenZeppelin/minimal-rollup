// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IProposerFees {
    /// @notice Emitted when a user deposits into the contract
    /// @param user The address that made the deposit
    /// @param amount The amount that the user deposited
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws from the contract
    /// @param user The address that made the withdrawal
    /// @param amount The amount that the user withdrew
    event Withdrawal(address indexed user, uint256 amount);

    /// @notice Proposers have to pay a fee for each publication they want to get proven. This should be called only by
    /// the Inbox contract.
    /// @param proposer The address of the proposer
    /// @param isDelayed Whether the publication is a delayed publication
    function payPublicationFee(address proposer, bool isDelayed) external;

    /// @notice Returns the current fees for a period
    /// @return fee The fee for a regular publication
    /// @return delayedFee The fee for a delayed publication
    function getCurrentFees() external view returns (uint96 fee, uint96 delayedFee);
}
