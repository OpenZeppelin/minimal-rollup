// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IProposerFees {
    /// @notice Proposers have to pay a fee for each publication they want to get proven. This should be called only by
    /// the Inbox contract.
    /// @param proposer The address of the proposer
    /// @param isDelayed Whether the publication is a delayed publication
    function payPublicationFee(address proposer, bool isDelayed) external payable;
}
