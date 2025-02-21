// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDataFeed {
    struct Publication {
        uint256 id;
        bytes32 prevHash;
        address publisher;
        uint256 timestamp;
        uint256 blockNumber;
    }

    /// @notice Emitted when a new publication is created
    /// @param pubHash the hash of the new publication and attributes
    /// @param publication the Publication struct describing the publication metadata
    /// @param attributes the data associated with the publication
    event Published(bytes32 indexed pubHash, Publication publication, bytes[] attributes);

    /// @notice Publish arbitrary data into the global queue.
    /// @param data the data to publish.
    function publish(bytes[] calldata data) external;

    /// @notice retrieve a hash representing a previous publication
    /// @param idx the index of the publication hash
    /// @return _ the corresponding publication hash
    function getPublicationHash(uint256 idx) external view returns (bytes32);
}
