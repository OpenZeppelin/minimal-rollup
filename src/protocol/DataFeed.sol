// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";
import {IMetadataProvider} from "./IMetadataProvider.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";

contract DataFeed is IDataFeed {
    using TransientSlot for *;

    // keccak256(abi.encode(uint256(keccak256("minimal-rollup.storage.TransactionGuard")) - 1)) &
    // ~bytes32(uint256(0xff))
    bytes32 internal constant _TRANSACTION_GUARD = 0x99b77697c9b37eb2c48d30bc6afcf1840fbb1ccae9217c44df166cd11b25cc00;

    /// @dev a list of hashes identifying all data accompanying calls to the `publish` function.
    bytes32[] public publicationHashes;

    modifier onlyStandaloneTx() {
        require(!_TRANSACTION_GUARD.asBoolean().tload());
        _TRANSACTION_GUARD.asBoolean().tstore(true);
        _;
        // Will clean up at the end of the transaction
    }

    constructor() {
        // guarantee there is always a previous hash
        publicationHashes.push(0);
    }

    /// @inheritdoc IDataFeed
    function publish(uint256 numBlobs, bytes calldata data, MetadataQuery[] calldata queries)
        external
        payable
        onlyStandaloneTx
    {
        uint256 nQueries = queries.length;
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
            metadata: new bytes[](nQueries)
        });

        for (uint256 i; i < numBlobs; ++i) {
            publication.blobHashes[i] = blobhash(i);
        }

        uint256 totalValue;
        for (uint256 i; i < nQueries; ++i) {
            publication.metadata[i] = IMetadataProvider(queries[i].provider).getMetadata{value: queries[i].value}(
                msg.sender, queries[i].input
            );
            totalValue += queries[i].value;
        }
        require(msg.value == totalValue, "Incorrect ETH passed with publication");

        bytes32 pubHash = keccak256(abi.encode(publication));
        publicationHashes.push(pubHash);

        emit Published(pubHash, publication);
    }

    /// @inheritdoc IDataFeed
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }
}
