// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

interface IMintableERC721 is IERC721 {
    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

interface IMintableERC1155 is IERC1155 {
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function burn(uint256 id, uint256 amount) external;
}
