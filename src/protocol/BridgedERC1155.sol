// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedTokenBase} from "./BridgedTokenBase.sol";
import {IMintableERC1155} from "./IMintable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title BridgedERC1155
/// @notice An ERC1155 token that represents a bridged token from another chain
/// @dev Only the bridge contract can mint and burn tokens
contract BridgedERC1155 is ERC1155, BridgedTokenBase, IMintableERC1155 {
    /// @dev Mapping from token ID to custom token URI
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory uri_, address _originalToken) ERC1155(uri_) BridgedTokenBase(_originalToken) {}

    /// @inheritdoc IMintableERC1155
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyOwner {
        _mint(to, id, amount, data);
    }

    /// @dev Mints tokens with custom URI
    /// @param to Address to mint the tokens to
    /// @param id Token ID to mint
    /// @param amount Amount to mint
    /// @param tokenURI_ Custom URI for this token
    /// @param data Additional data
    function mintWithURI(address to, uint256 id, uint256 amount, string memory tokenURI_, bytes memory data)
        external
        onlyOwner
    {
        _mint(to, id, amount, data);
        _setTokenURI(id, tokenURI_);
    }

    /// @inheritdoc IMintableERC1155
    function burn(uint256 id, uint256 amount) external onlyOwner {
        _burn(msg.sender, id, amount);
    }

    /// @dev See {IERC1155MetadataURI-uri}.
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return super.uri(tokenId);
    }

    /// @dev Sets the token URI for a specific token
    /// @param tokenId Token ID to set URI for
    /// @param tokenURI_ URI to set
    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal {
        _tokenURIs[tokenId] = tokenURI_;
    }
}
