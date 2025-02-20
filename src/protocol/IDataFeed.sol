// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IDataFeed {
    struct HookQuery {
        address provider;
        bytes input;
        uint256 value;
    }

    struct Publication {
        uint256 id;
        bytes32 prevHash;
        address publisher;
        uint256 timestamp;
        uint256 blockNumber;
        bytes data;
        HookQuery[] preHookQueries;
        HookQuery[] postHookQueries;
        bytes[] auxData;
    }

    /// @notice Emitted when a new publication is created
    /// @param pubHash the hash of the new publication
    /// @param publication the Publication struct describing the preimages to pubHash
    event Published(bytes32 indexed pubHash, Publication publication);

    /// @notice Publish arbitrary data for data availability.
    /// @param data the data to publish in calldata.
    /// @param preHookQueries arbitrary calls to retrieve auxiliary data that should be contained in the publication
    /// @param postHookQueries arbitrary calls to be executed after the publication
    /// @dev there can be multiple pre hooks and post hooks because a single publication might represent multiple
    /// rollups,
    /// each with their own requirements
    function publish(bytes calldata data, HookQuery[] calldata preHookQueries, HookQuery[] calldata postHookQueries)
        external
        payable;

    /// @notice retrieve a hash representing a previous publication
    /// @param idx the index of the publication hash
    /// @return _ the corresponding publication hash
    function getPublicationHash(uint256 idx) external view returns (bytes32);
}
