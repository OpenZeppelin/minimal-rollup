// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDataFeed {
    struct PublicationHeader {
        uint256 id;
        bytes32 prevHash;
        address publisher;
        uint256 timestamp;
        uint256 blockNumber;
    }

    /// @notice Emitted when a new publication is created
    /// @param pubHash the hash of the new publication
    /// @param header the metadata associated with the publication
    /// @param attributes the data contained within the publication
    event Published(bytes32 indexed pubHash, PublicationHeader header, bytes[] attributes);

    /// @notice Publish arbitrary data into the global queue.
    /// @param attributes the data to publish.
    /// @dev the data is encoded as an array so each attribute is hashed independently,
    /// which allows a single attribute to be validated against a pubHash
    function publish(bytes[] calldata attributes) external;

    /// @notice retrieve a hash representing a previous publication
    /// @param idx the index of the publication hash
    /// @return _ the corresponding publication hash
    function getPublicationHash(uint256 idx) external view returns (bytes32);
}
