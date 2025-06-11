// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockERC20
/// @notice A simple mock implementation of ERC20 for testing purposes
contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MOCK") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
