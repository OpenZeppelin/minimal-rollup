// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockMaliciousERC20
/// @notice A malicious ERC20 token that spoofs the bridge() function
/// @dev Used to test that the bridge properly rejects spoofed bridged tokens
contract MockMaliciousERC20 is ERC20 {
    address private _fakeBridge;

    constructor(address fakeBridge) ERC20("Malicious Token", "EVIL") {
        _fakeBridge = fakeBridge;
        _mint(msg.sender, 1000000 * 10**18);
    }

    /// @dev Spoofs the bridge() function to return the provided address
    function bridge() external view returns (address) {
        return _fakeBridge;
    }

    /// @dev Fake originalToken function to make it look like a bridged token
    function originalToken() external pure returns (address) {
        return address(0x1); // Fake original token
    }
} 