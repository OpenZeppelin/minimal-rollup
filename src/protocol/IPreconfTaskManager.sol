// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

/// @notice Dummy interface to return the current validator that has monopoly rights over the L2
///         An alternative way is to expose to proposeCheckpoint function here and restrict the `msg.sender` in the
///         Inbox contract
interface IPreconfTaskManager {
    /// @notice Returns the validator that has the right to propose at a specific timestamp
    function getPreconfer(uint256 timestamp) external view returns (address);
}
