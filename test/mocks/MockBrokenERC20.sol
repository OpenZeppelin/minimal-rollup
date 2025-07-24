// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockBrokenERC20
/// @notice A mock ERC20 token that doesn't implement metadata functions properly
/// @dev Used to test the try-catch fallbacks in the bridge
contract MockBrokenERC20 is ERC20 {
    constructor() ERC20("", "") {
        _mint(msg.sender, 1000000 * 10**18);
    }

    // Override metadata functions to revert, simulating a broken token
    function name() public pure override returns (string memory) {
        revert("Name not supported");
    }

    function symbol() public pure override returns (string memory) {
        revert("Symbol not supported");
    }

    function decimals() public pure override returns (uint8) {
        revert("Decimals not supported");
    }
} 