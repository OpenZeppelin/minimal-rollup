// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";
import {IPublicationHook} from "./IPublicationHook.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";

contract DataFeed is IDataFeed {
    /// @dev a list of hashes identifying all data accompanying calls to the `publish` function.
    bytes32[] public publicationHashes;

    constructor() {
        // guarantee there is always a previous hash
        publicationHashes.push(0);
    }

    /// @inheritdoc IDataFeed
    function publish(uint256 numBlobs, bytes calldata data, HookQuery[] calldata queries) external payable {
        uint256 nQueries = queries.length;

        uint256 totalValue;
        bytes[] memory metadata = new bytes[](nQueries);
        for (uint256 i; i < nQueries; ++i) {
            metadata[i] = IPublicationHook(queries[i].provider).beforePublish{value: queries[i].value}(
                msg.sender, queries[i].input
            );
            totalValue += queries[i].value;
        }
        require(msg.value == totalValue, "Incorrect ETH passed with publication");

        uint256 id = publicationHashes.length;

        Publication memory publication = Publication({
            id: id,
            prevHash: publicationHashes[id - 1],
            publisher: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number,
            blobHashes: new bytes32[](numBlobs),
            data: data,
            queries: queries,
            metadata: metadata
        });

        for (uint256 i; i < numBlobs; ++i) {
            publication.blobHashes[i] = blobhash(i);
        }

        bytes32 pubHash = keccak256(abi.encode(publication));
        publicationHashes.push(pubHash);

        for (uint256 i; i < nQueries; ++i) {
            // TODO: handle after_publish
            IPublicationHook(queries[i].provider).afterPublish{value: queries[i].value}(msg.sender, queries[i].input);
        }

        emit Published(pubHash, publication);
    }

    /// @inheritdoc IDataFeed
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }
}
