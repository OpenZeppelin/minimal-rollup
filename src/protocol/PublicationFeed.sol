// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IPublicationFeed} from "./IPublicationFeed.sol";

contract PublicationFeed is IPublicationFeed {
    /// @dev a list of hashes identifying all data accompanying calls to the `publish` function.
    bytes32[] public publicationHashes;

    constructor() {
        // guarantee there is always a previous hash
        publicationHashes.push(0);
    }

    /// @inheritdoc IPublicationFeed
    function publish(bytes[] calldata attributes) external override returns (PublicationHeader memory header) {
        uint256 nAttributes = attributes.length;
        bytes32[] memory attributeHashes = new bytes32[](nAttributes);
        for (uint256 i; i < nAttributes; ++i) {
            attributeHashes[i] = keccak256(attributes[i]);
        }

        uint256 id = publicationHashes.length;
        header = PublicationHeader({
            id: id,
            prevHash: publicationHashes[id - 1],
            publisher: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number,
            attributesHash: keccak256(abi.encode(attributeHashes))
        });

        bytes32 pubHash = keccak256(abi.encode(header));
        publicationHashes.push(pubHash);

        emit Published(pubHash, header, attributes);
    }

    /// @inheritdoc IPublicationFeed
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }

    /// @inheritdoc IPublicationFeed
    function getNextPublicationId() external view returns (uint256) {
        return publicationHashes.length;
    }

    /// @inheritdoc IPublicationFeed
    function validateHeader(PublicationHeader calldata header) external view returns (bool) {
        return keccak256(abi.encode(header)) == publicationHashes[header.id];
    }
}
