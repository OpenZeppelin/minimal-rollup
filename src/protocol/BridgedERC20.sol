// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IMintableERC20} from "./IMintable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title BridgedERC20
/// @notice An ERC20 token that represents a bridged token from another chain
/// @dev Only the bridge contract can mint and burn tokens
contract BridgedERC20 is ERC20, IMintableERC20 {
    /// @notice The bridge contract that can mint and burn tokens
    address public immutable bridge;

    /// @notice The original token address on the source chain
    address public immutable originalToken;

    /// @notice The source chain identifier (could be chain ID or other identifier)
    uint256 public immutable sourceChain;

    error OnlyBridge();

    modifier onlyBridge() {
        if (msg.sender != bridge) revert OnlyBridge();
        _;
    }

    uint8 private immutable _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        address _bridge,
        address _originalToken,
        uint256 _sourceChain
    ) ERC20(name, symbol) {
        bridge = _bridge;
        originalToken = _originalToken;
        sourceChain = _sourceChain;
        _decimals = decimals_;
    }

    /// @inheritdoc IMintableERC20
    function mint(address to, uint256 amount) external onlyBridge {
        _mint(to, amount);
    }

    /// @inheritdoc IMintableERC20
    function burn(address from, uint256 amount) external onlyBridge {
        _burn(from, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
