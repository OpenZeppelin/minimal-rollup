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

    /// @dev a list of hashes identifying all data passed to the `directPublish` function.
    bytes32[] public directPublicationHashes;

    modifier onlyStandaloneTx() {
        require(!_TRANSACTION_GUARD.asBoolean().tload());
        _TRANSACTION_GUARD.asBoolean().tstore(true);
        _;
        // Will clean up at the end of the transaction
    }

    constructor() {
        // guarantee there is always a previous hash
        publicationHashes.push(0);
        directPublicationHashes.push(0);
    }

    /// @inheritdoc IDataFeed
    function publish(uint256 numBlobs, MetadataQuery[] calldata queries) external payable onlyStandaloneTx {
        require(numBlobs > 0, "no data to publish");

        uint256 id = publicationHashes.length;
        uint256 directId = directPublicationHashes.length;
        Publication memory publication = Publication({
            id: id,
            prevHash: publicationHashes[id - 1],
            publisher: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number,
            blobHashes: new bytes32[](numBlobs),
            queries: queries,
            metadata: new bytes[](queries.length),
            directPublicationId: directId,
            directPublicationHash: directPublicationHashes[directId - 1]
        });

        for (uint256 i; i < numBlobs; ++i) {
            publication.blobHashes[i] = blobhash(i);
        }

        _setMetadata(publication.metadata, queries);

        bytes32 pubHash = keccak256(abi.encode(publication));
        publicationHashes.push(pubHash);

        emit Published(pubHash, publication);
    }

    /// @inheritdoc IDataFeed
    function directPublish(bytes calldata data, MetadataQuery[] calldata queries) external payable {
        require(data.length > 0, "no data to publish");

        uint256 id = directPublicationHashes.length;
        DirectPublication memory publication = DirectPublication({
            id: id,
            prevHash: directPublicationHashes[id - 1],
            publisher: msg.sender,
            timestamp: block.timestamp,
            blockNumber: block.number,
            dataHash: keccak256(data),
            queries: queries,
            metadata: new bytes[](queries.length)
        });

        _setMetadata(publication.metadata, queries);

        bytes32 pubHash = keccak256(abi.encode(publication));
        directPublicationHashes.push(pubHash);

        emit DirectPublished(pubHash, publication);
    }

    function _setMetadata(bytes[] memory metadata, MetadataQuery[] calldata queries) internal {
        uint256 nQueries = queries.length;
        uint256 totalValue;
        for (uint256 i; i < nQueries; ++i) {
            metadata[i] = IMetadataProvider(queries[i].provider).getMetadata{value: queries[i].value}(
                msg.sender, queries[i].input
            );
            totalValue += queries[i].value;
        }
        require(msg.value == totalValue, "Incorrect ETH passed with publication");
    }

    /// @inheritdoc IDataFeed
    function getPublicationHash(uint256 idx) external view returns (bytes32) {
        return publicationHashes[idx];
    }

    /// @inheritdoc IDataFeed
    function getDirectPublicationHash(uint256 idx) external view returns (bytes32) {
        return directPublicationHashes[idx];
    }
}
