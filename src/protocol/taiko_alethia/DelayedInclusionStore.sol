//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";
import {IDelayedInclusionStore} from "../IDelayedInclusionStore.sol";

contract DelayedInclusionStore is IDelayedInclusionStore {
    struct DueInclusion {
        bytes32 blobRefHash;
        uint256 due;
    }

    // Append-only queue for delayed inclusions
    DueInclusion[] private delayedInclusions;
    // Pointer to the first unprocessed element
    uint256 private head;

    uint256 public immutable inclusionDelay;

    address public immutable inbox;

    IBlobRefRegistry public immutable blobRefRegistry;

    /// @param _inclusionDelay The delay before next set of inclusions can be processed.
    /// @param _blobRefRegistry The address of the blob reference registry contract.
    /// @param _taikoInbox The address of the Taiko's inbox contract responsible for processing inclusions.
    constructor(uint256 _inclusionDelay, address _blobRefRegistry, address _taikoInbox) {
        inclusionDelay = _inclusionDelay;
        inbox = _taikoInbox;
        blobRefRegistry = IBlobRefRegistry(_blobRefRegistry);
    }

    /// @dev Retrieves a blob reference from the blob reference registry
    /// and stores the hash (Inclusion) in the delayed inclusion queue.
    /// @param blobIndices An array of blob indices to be registered.
    function publishDelayed(uint256[] calldata blobIndices) external {
        bytes32 refHash = keccak256(abi.encode(blobRefRegistry.getRef(blobIndices)));
        delayedInclusions.push(DueInclusion(refHash, block.timestamp + inclusionDelay));
    }

    /// @inheritdoc IDelayedInclusionStore
    /// @dev Only returns inclusions if the delay period has passed
    /// otherwise returns an empty array.
    /// @dev Can only be called by the inbox contract.
    function processDueInclusions() external returns (Inclusion[] memory) {
        uint256 len = delayedInclusions.length;
        if (head >= len) {
            return new Inclusion[](0);
        }

        uint256 l = head;
        uint256 r = len;
        uint256 timestamp = block.timestamp;
        while (l < r) {
            uint256 mid = (l + r) >> 1;
            if (delayedInclusions[mid].due <= timestamp) {
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

        require(msg.sender == inbox, "Only inbox can process inclusions");

        Inclusion[] memory inclusions = new Inclusion[](count);
        for (uint256 i = 0; i < count; ++i) {
            inclusions[i] = Inclusion(delayedInclusions[head + i].blobRefHash);
        }

        // Move the head pointer forward.
        head = l;

        return inclusions;
    }
}
