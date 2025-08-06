// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title BridgedTokenBase
/// @notice Common base contract for all bridged tokens
/// @dev Provides ownership control and original token tracking. Uses OpenZeppelin's Ownable for access control.
abstract contract BridgedTokenBase is Ownable {
    /// @notice Address of the original token on the source chain
    address public immutable originalToken;

    /// @dev Constructor sets the deployer (bridge) as owner and stores original token address
    /// @param _originalToken Address of the original token on the source chain
    constructor(address _originalToken) Ownable(msg.sender) {
        originalToken = _originalToken;
    }
}
