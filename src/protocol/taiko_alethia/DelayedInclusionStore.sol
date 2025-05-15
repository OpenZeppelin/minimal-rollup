//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";
import {IDelayedInclusionStore} from "../IDelayedInclusionStore.sol";

/// @dev A contract that handles storing publications that will be included by the inbox contract at a delayed time.
///
/// Offers a simple interface to handle storing and processing delayed inclusions.
/// The contract is designed to be used in conjunction with a rollup's inbox contract.
/// Delayed inclusions are added to a queue using the `publishDelayed` function and are processed by
/// calling the `processDueInclusions` function.
abstract contract DelayedInclusionStore is IDelayedInclusionStore {
    struct DueInclusion {
        bytes32 blobRefHash;
        uint256 due;
    }

    /// @notice Emitted when a delayed publication is stored
    /// @param sender The address that stored the delayed publication
    /// @param dueInclusion The delayed publication including the blob reference hash and due timestamp
    event DelayedInclusionStored(address indexed sender, DueInclusion dueInclusion);

    // Append-only queue for delayed inclusions
    DueInclusion[] private _delayedInclusions;

    // Pointer to the first unprocessed element
    uint256 private _head;

    /// @notice The minimum amount of time a delayed publication needs to
    /// wait in the queue to be included expressed in seconds
    uint256 public immutable inclusionDelay;

    IBlobRefRegistry public immutable blobRefRegistry;

    /// @param _inclusionDelay The delay before next set of inclusions can be processed.
    /// @param _blobRefRegistry The address of the blob reference registry.
    constructor(uint256 _inclusionDelay, address _blobRefRegistry) {
        inclusionDelay = _inclusionDelay;
        blobRefRegistry = IBlobRefRegistry(_blobRefRegistry);
    }

    /// @inheritdoc IDelayedInclusionStore
    /// @dev Stores the blob reference as a DueInclusion
    function publishDelayed(uint256[] memory blobIndices) external virtual {
        (bytes32 refHash,) = blobRefRegistry.registerRef(blobIndices);
        DueInclusion memory dueInclusion = DueInclusion(refHash, block.timestamp + inclusionDelay);
        _delayedInclusions.push(dueInclusion);
        emit DelayedInclusionStored(msg.sender, dueInclusion);
    }

    /// @notice Returns a list of publications that should be processed by the Inbox
    /// @dev Only returns inclusions if the delay period has passed
    /// otherwise returns an empty array.
    function processDueInclusions() internal virtual returns (Inclusion[] memory) {
        uint256 len = _delayedInclusions.length;
        uint256 head = _head;
        if (head >= len) {
            return new Inclusion[](0);
        }

        uint256 l = head;
        uint256 r = len;
        uint256 timestamp = block.timestamp;
        while (l < r) {
            uint256 mid = (l + r) >> 1;
            if (_delayedInclusions[mid].due <= timestamp) {
                // If inclusion at mid is due, search to the right.
                l = mid + 1;
            } else {
                r = mid;
            }
        }

        // l now is the first index where the inclusion is not yet due.
        uint256 count = l - head;
        if (count == 0) {
            return new Inclusion[](0);
        }

        Inclusion[] memory inclusions = new Inclusion[](count);
        for (uint256 i = 0; i < count; ++i) {
            inclusions[i] = Inclusion(_delayedInclusions[head + i].blobRefHash);
        }

        emit DelayedInclusionProcessed(inclusions);

        // Move the head pointer forward.
        _head = l;

        return inclusions;
    }
}
