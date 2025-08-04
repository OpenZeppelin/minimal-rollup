// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMintableERC20 is IERC20 {
    /// @notice Mints new tokens to the specified address
    /// @param to The address to mint tokens to
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external;

    /// @notice Burns tokens from the caller's address
    /// @param amount The amount of tokens to burn∂
    function burn(uint256 amount) external;
}

interface IMintableERC721 is IERC721 {
    /// @notice Mints a new token to the specified address with a custom URI
    /// @param to The address to mint the token to
    /// @param tokenId The ID of the token to mint
    /// @param tokenURI_ The URI for the token∂
    function mint(address to, uint256 tokenId, string memory tokenURI_) external;

    /// @notice Burns the specified token
    /// @param tokenId The ID of the token to burn
    function burn(uint256 tokenId) external;
}

interface IMintableERC1155 is IERC1155 {
    /// @notice Mints new tokens to the specified address
    /// @param to The address to mint tokens to
    /// @param id The ID of the token to mint
    /// @param amount The amount of tokens to mint
    /// @param data Additional data to pass with the minting operation
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    /// @notice Burns tokens of the specified ID from the caller's address
    /// @param id The ID of the token to burn
    /// @param amount The amount of tokens to burn
    function burn(uint256 id, uint256 amount) external;
}
