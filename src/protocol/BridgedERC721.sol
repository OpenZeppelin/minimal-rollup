// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedTokenBase} from "./BridgedTokenBase.sol";
import {IMintableERC721} from "./IMintable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title BridgedERC721
/// @notice An ERC721 token that represents a bridged token from another chain
/// @dev Only the bridge contract can mint and burn tokens
/// @dev Implements the ERC721Metadata interface, whether or not the original token supports it
contract BridgedERC721 is ERC721, BridgedTokenBase, IMintableERC721 {
    /// @dev Mapping from token ID to custom token URI
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name, string memory symbol, address _originalToken)
        ERC721(name, symbol)
        BridgedTokenBase(_originalToken)
    {}

    /// @inheritdoc IMintableERC721
    function mint(address to, uint256 tokenId, string memory tokenURI_) external onlyOwner {
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = tokenURI_;
    }

    /// @inheritdoc IMintableERC721
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        delete _tokenURIs[tokenId];
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURIs[tokenId];
    }
}
