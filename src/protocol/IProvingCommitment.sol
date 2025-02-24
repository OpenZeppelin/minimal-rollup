// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

//TODO: finalize natspec
interface IProvingCommitment {
    /// @notice Allows proposers to pay for their publication.
    function payForPublication() external payable;

    /// @notice Allows a prover to commit to prove a period.
    function commitToProve(uint256 periodId) external;

    /// @notice Allows a prover to finalize their commitment to prove a period.
    function finalizeCommitment(uint256 periodId, address caller) external;
}
