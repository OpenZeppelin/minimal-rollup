// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IProposerFees {
    /// @notice Proposers have to pay a fee for each publication they want to get proven. This should be called only by
    /// the Inbox contract.
    /// @param proposer The address of the proposer
    /// @param isDelayed Whether the publication is a delayed publication
    function payPublicationFee(address proposer, bool isDelayed) external payable;

    /// @notice Returns the current fees for a period
    /// @return fee The fee for a regular publication
    /// @return delayedFee The fee for a delayed publication
    function getCurrentFees() external view returns (uint256 fee, uint256 delayedFee);
}
