// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IMintableERC1155} from "../../src/protocol/IMintable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155, IMintableERC1155 {
    constructor() ERC1155("") {}

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external {
        _mint(to, id, amount, data);
    }

    function burn(address from, uint256 id, uint256 amount) external {
        _burn(from, id, amount);
    }
}
