// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IDataFeed} from "./IDataFeed.sol";
import {IMetadataProvider} from "./IMetadataProvider.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";

contract DataFeed is IDataFeed {
    using TransientSlot for *;

    // keccak256(abi.encode(uint256(keccak256("minimal-rollup.storage.TransactionGuard")) - 1)) &
    // ~bytes32(uint256(0xff))
    bytes32 private constant _TRANSACTION_GUARD = 0x99b77697c9b37eb2c48d30bc6afcf1840fbb1ccae9217c44df166cd11b25cc00;

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

    /// @notice Publish arbitrary data in blobs for data availability.
    /// @param numBlobs the number of blobs accompanying this function call.
    /// @param queries the calls required to retrieve L1 metadata hashes associated with this publication.
    /// @dev there can be multiple queries because a single publication might represent multiple rollups,
    /// each with their own L1 metadata requirements
    /// @dev append a hash representing all blobs and L1 metadata to `publicationHashes`.
    /// The number of blobs is not validated. Additional blobs are ignored. Empty blobs have a hash of zero.
    function publish(uint256 numBlobs, MetadataQuery[] calldata queries) external payable onlyStandaloneTx {
        require(numBlobs > 0, "no data to publish");

        uint256 nQueries = queries.length;
        Publication memory publication = Publication({
            publisher: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number,
            blobHashes: new bytes32[](numBlobs),
            queries: queries,
            metadata: new bytes[](nQueries)
        });

        for (uint256 i; i < numBlobs; ++i) {
            publication.blobHashes[i] = blobhash(i);
        }

        uint256 totalValue;
        for (uint256 i; i < nQueries; ++i) {
            publication.metadata[i] = IMetadataProvider(queries[i].provider).getMetadata(msg.sender, queries[i].input);
            totalValue += queries[i].value;
        }
        require(msg.value == totalValue, "Incorrect ETH passed with publication");

        bytes32 prevHash = publicationHashes[publicationHashes.length - 1];
        bytes32 pubHash = keccak256(abi.encode(prevHash, publication));
        publicationHashes.push(pubHash);

        emit Published(pubHash, publication);
    }

    /// @notice retrieve a hash representing a previous publication
    /// @param idx the index of the publication hash
    /// @return _ the corresponding publication hash
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }
}
