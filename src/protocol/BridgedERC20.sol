// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedTokenBase} from "./BridgedTokenBase.sol";
import {IMintableERC20} from "./IMintable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title BridgedERC20
/// @notice An ERC20 token that represents a bridged token from another chain
/// @dev Only the bridge contract can mint and burn tokens
/// @dev Implements the optional metadata functions, whether or not the original token supports them
contract BridgedERC20 is ERC20, BridgedTokenBase, IMintableERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_, address _originalToken)
        ERC20(name, symbol)
        BridgedTokenBase(_originalToken)
    {
        _decimals = decimals_;
    }

    /// @inheritdoc IMintableERC20
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @inheritdoc IMintableERC20
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
