// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";

contract DataFeed is IDataFeed {
    /// @dev a list of hashes identifying all data accompanying calls to the `publish` function.
    bytes32[] public publicationHashes;

    constructor() {
        // guarantee there is always a previous hash
        publicationHashes.push(0);
    }

    /// @inheritdoc IDataFeed
    function publish(bytes[] calldata attributes) external override {
        uint256 id = publicationHashes.length;
        PublicationHeader memory header = PublicationHeader({
            id: id,
            prevHash: publicationHashes[id - 1],
            publisher: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number
        });

        uint256 nAttributes = attributes.length;
        bytes32[] memory attributeHashes = new bytes32[](nAttributes);
        for (uint256 i; i < nAttributes; ++i) {
            attributeHashes[i] = keccak256(attributes[i]);
        }
        bytes32 pubHash = keccak256(abi.encode(header, attributeHashes));
        publicationHashes.push(pubHash);

        emit Published(pubHash, header, attributes);
    }

    /// @inheritdoc IDataFeed
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }
}
