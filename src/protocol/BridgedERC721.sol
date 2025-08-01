// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedTokenBase} from "./BridgedTokenBase.sol";
import {IMintableERC721} from "./IMintable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title BridgedERC721
/// @notice An ERC721 token that represents a bridged token from another chain
/// @dev Only the bridge contract can mint and burn tokens
contract BridgedERC721 is ERC721, BridgedTokenBase, IMintableERC721 {
    /// @dev Mapping from token ID to custom token URI
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name, string memory symbol, address _originalToken)
        ERC721(name, symbol)
        BridgedTokenBase(_originalToken)
    {}

    /// @inheritdoc IMintableERC721
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    /// @dev Mints a token with custom URI
    /// @param to Address to mint the token to
    /// @param tokenId Token ID to mint
    /// @param tokenURI_ Custom URI for this token
    function mintWithURI(address to, uint256 tokenId, string memory tokenURI_) external onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }

    /// @inheritdoc IMintableERC721
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    /// @dev Sets the token URI for a specific token
    /// @param tokenId Token ID to set URI for
    /// @param tokenURI_ URI to set
    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal {
        _tokenURIs[tokenId] = tokenURI_;
    }
}
