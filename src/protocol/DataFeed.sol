// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";
import {IPublicationHook} from "./IPublicationHook.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";

contract DataFeed is IDataFeed {
    using TransientSlot for *;

    // keccak256(abi.encode(uint256(keccak256("minimal-rollup.storage.PublisherSlot")) - 1)) &
    // ~bytes32(uint256(0xff));
    bytes32 private constant _PUBLISHER_SLOT = 0xc8658bb11ce958514230cc55a245b4aa68d7de7043c4fad93bb491e28ddc7c00;

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
        HookQuery[] calldata preHookQueries,
        HookQuery[] calldata postHookQueries
    ) external payable {
        address publisher = _getPublisher();

        uint256 nHooks = preHookQueries.length;
        uint256 totalValue;
        bytes[] memory auxData = new bytes[](nHooks);
        for (uint256 i; i < nHooks; ++i) {
            auxData[i] = IPublicationHook(preHookQueries[i].provider).beforePublish{value: preHookQueries[i].value}(
                publisher, preHookQueries[i].input
            );
            totalValue += preHookQueries[i].value;
        }

        uint256 id = publicationHashes.length;
        Publication memory publication = Publication({
            id: id,
            prevHash: publicationHashes[id - 1],
            publisher: publisher,
            timestamp: block.timestamp,
            blockNumber: block.number,
            blobHashes: new bytes32[](numBlobs),
            data: data,
            preHookQueries: preHookQueries,
            postHookQueries: postHookQueries,
            auxData: auxData
        });

        for (uint256 i; i < numBlobs; ++i) {
            publication.blobHashes[i] = blobhash(i);
        }

        bytes32 pubHash = keccak256(abi.encode(publication));
        publicationHashes.push(pubHash);

        nHooks = postHookQueries.length;
        for (uint256 i; i < nHooks; ++i) {
            IPublicationHook(postHookQueries[i].provider).afterPublish{value: postHookQueries[i].value}(
                publisher, publication, postHookQueries[i].input
            );
            totalValue += postHookQueries[i].value;
        }
        require(msg.value == totalValue, "Incorrect ETH passed with publication");

        emit Published(pubHash, publication);
    }

    /// @inheritdoc IDataFeed
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }

    function _getPublisher() internal returns (address publisher) {
        publisher = _PUBLISHER_SLOT.asAddress().tload();
        if (publisher == address(0)) {
            publisher = msg.sender;
            _PUBLISHER_SLOT.asAddress().tstore(publisher);
        }
    }
}
