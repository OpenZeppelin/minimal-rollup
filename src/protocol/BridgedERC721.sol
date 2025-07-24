// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IMintableERC721} from "./IMintable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title BridgedERC721
/// @notice An ERC721 token that represents a bridged token from another chain
/// @dev Only the bridge contract can mint and burn tokens
contract BridgedERC721 is ERC721, IMintableERC721 {
    /// @dev Mapping from token ID to custom token URI
    mapping(uint256 => string) private _tokenURIs;
    /// @notice The bridge contract that can mint and burn tokens
    address public immutable bridge;

    /// @notice The original token address on the source chain
    address public immutable originalToken;

    error OnlyBridge();

    modifier onlyBridge() {
        if (msg.sender != bridge) revert OnlyBridge();
        _;
    }

    constructor(string memory name, string memory symbol, address _bridge, address _originalToken)
        ERC721(name, symbol)
    {
        bridge = _bridge;
        originalToken = _originalToken;
    }

    /// @inheritdoc IMintableERC721
    function mint(address to, uint256 tokenId) external onlyBridge {
        _mint(to, tokenId);
    }

    /// @dev Mints a token with custom URI
    /// @param to Address to mint the token to
    /// @param tokenId Token ID to mint
    /// @param tokenURI_ Custom URI for this token
    function mintWithURI(address to, uint256 tokenId, string memory tokenURI_) external onlyBridge {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
    }

    /// @inheritdoc IMintableERC721
    function burn(address from, uint256 tokenId) external onlyBridge {
        _burn(tokenId);
        // Clear the token URI when burning
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is a custom URI for this token, return it
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        // Otherwise, fall back to the default behavior
        return super.tokenURI(tokenId);
    }

    /// @dev Sets the token URI for a specific token
    /// @param tokenId Token ID to set URI for
    /// @param tokenURI_ URI to set
    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal {
        _tokenURIs[tokenId] = tokenURI_;
    }
}
