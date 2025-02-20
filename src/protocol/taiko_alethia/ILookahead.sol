// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ILookahead {
    /// @notice Returns true if the address is a current preconfer
    /// @param addr The address to check
    /// @return isPreconfer True if the address is a current preconfer
    function isCurrentPreconfer(address addr) external returns (bool);
}
