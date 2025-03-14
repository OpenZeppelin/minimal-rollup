// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IPublicationFeed {
    struct PublicationHeader {
        uint256 id;
        bytes32 prevHash;
        address publisher;
        uint256 timestamp;
        uint256 blockNumber;
        bytes32 attributesHash;
    }

    /// @notice Emitted when a new publication is created
    /// @param pubHash The hash of the new publication
    /// @param header The metadata associated with the publication
    /// @param attributes The data contained within the publication
    event Published(bytes32 indexed pubHash, PublicationHeader header, bytes[] attributes);

    /// @notice Publish arbitrary data into the global queue
    /// @param attributes The data to publish
    /// @return header The publication header
    /// @dev The data is encoded as an array so each attribute is hashed independently,
    /// which allows a single attribute to be validated against a pubHash
    function publish(bytes[] calldata attributes) external returns (PublicationHeader memory header);

    /// @notice Retrieve a hash representing a previous publication
    /// @param idx The index of the publication hash
    /// @return _ The corresponding publication hash
    function getPublicationHash(uint256 idx) external view returns (bytes32);

    /// @notice Returns the next publication's ID.
    /// @return _ The next publication ID.
    function getNextPublicationId() external view returns (uint256);

    /// @notice Validate a publication header against the hash stored in the feed
    /// @param header The header to validate
    /// @param idx The index of the publication hash
    /// @return _ True if the header is valid, false otherwise
    function validateHeader(PublicationHeader calldata header, uint256 idx) external view returns (bool);
}
