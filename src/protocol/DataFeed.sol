// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";
import {IPublicationHook} from "./IPublicationHook.sol";

contract DataFeed is IDataFeed {
    /// @dev a list of hashes identifying all data accompanying calls to the `publish` function.
    bytes32[] public publicationHashes;

    constructor() {
        // guarantee there is always a previous hash
        publicationHashes.push(0);
    }

    /// @inheritdoc IDataFeed
    function publish(
        uint256 numBlobs,
        bytes calldata data,
        HookQuery[] calldata preHooks,
        HookQuery[] calldata postHooks
    ) external payable {
        uint256 nHooks = preHooks.length;
        uint256 totalValue;
        bytes[] memory auxData = new bytes[](nHooks);
        for (uint256 i; i < nHooks; ++i) {
            auxData[i] = IPublicationHook(preHooks[i].provider).beforePublish{value: preHooks[i].value}(
                msg.sender, preHooks[i].input
            );
            totalValue += preHooks[i].value;
        }

        uint256 id = publicationHashes.length;
        Publication memory publication = Publication({
            id: id,
            prevHash: publicationHashes[id - 1],
            publisher: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number,
            blobHashes: new bytes32[](numBlobs),
            data: data,
            preHooks: preHooks,
            postHooks: postHooks,
            auxData: auxData
        });

        for (uint256 i; i < numBlobs; ++i) {
            publication.blobHashes[i] = blobhash(i);
        }

        bytes32 pubHash = keccak256(abi.encode(publication));
        publicationHashes.push(pubHash);

        nHooks = postHooks.length;
        for (uint256 i; i < nHooks; ++i) {
            IPublicationHook(postHooks[i].provider).afterPublish{value: postHooks[i].value}(
                msg.sender, publication, postHooks[i].input
            );
            totalValue += postHooks[i].value;
        }
        require(msg.value == totalValue, "Incorrect ETH passed with publication");

        emit Published(pubHash, publication);
    }

    /// @inheritdoc IDataFeed
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }
}
