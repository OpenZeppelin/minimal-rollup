// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IInbox} from "src/protocol/IInbox.sol";

/// @notice Mock implementation of IInbox for testing
contract MockInbox is IInbox {
    bytes32[] private _publicationHashes;
    mapping(uint256 => PublicationHeader) private _headers;

    constructor() {
        // guarantee there is always a previous hash (genesis)
        _publicationHashes.push(bytes32(0));
    }

    /// @inheritdoc IInbox
    function publish(uint256 nBlobs, uint64 anchorBlockId) external {
        // Simple mock implementation
        uint256 id = _publicationHashes.length;

        PublicationHeader memory header = PublicationHeader({
            id: id,
            prevHash: _publicationHashes[id - 1],
            publisher: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number,
            attributesHash: keccak256(abi.encode(nBlobs, anchorBlockId))
        });

        bytes32 pubHash = keccak256(abi.encode(header));
        _publicationHashes.push(pubHash);
        _headers[id] = header;

        // Create mock attributes
        bytes[] memory attributes = new bytes[](2);
        attributes[0] = abi.encode("metadata");
        attributes[1] = abi.encode("blobRef");

        emit Published(pubHash, header, attributes);
    }

    /// @inheritdoc IInbox
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        require(idx < _publicationHashes.length, "Publication does not exist");
        return _publicationHashes[idx];
    }

    /// @inheritdoc IInbox
    function getNextPublicationId() external view returns (uint256) {
        return _publicationHashes.length;
    }

    /// @inheritdoc IInbox
    function validateHeader(PublicationHeader calldata header) external view returns (bool) {
        if (header.id >= _publicationHashes.length) {
            return false;
        }
        return keccak256(abi.encode(header)) == _publicationHashes[header.id];
    }

    /// @notice Get a stored header for testing purposes
    /// @param id The publication ID
    /// @return The stored header
    function getHeader(uint256 id) external view returns (PublicationHeader memory) {
        require(id < _publicationHashes.length, "Publication does not exist");
        return _headers[id];
    }
}
