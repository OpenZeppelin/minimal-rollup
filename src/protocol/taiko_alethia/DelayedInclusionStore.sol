//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";
import {IDelayedInclusionStore} from "../IDelayedInclusionStore.sol";

contract DelayedInclusionStore is IDelayedInclusionStore {
    struct DueInclusion {
        bytes32 blobRefHash;
        uint256 due;
    }

    /// @notice Emitted when a delayed publication is stored
    /// @param dueInclusion The delayed publication including
    /// the blob reference hash and due timestamp
    /// @param sender The address that stored the delayed publication
    event DelayedInclusionStored(address indexed sender, DueInclusion dueInclusion);

    /// @notice Emitted when a list of delayed inclusions are processed by the inbox
    /// @param inclusionsList list of inclusions
    event DelayedInclusionProcessed(Inclusion[] inclusionsList);

    // Append-only queue for delayed inclusions
    DueInclusion[] private delayedInclusions;

    // Pointer to the first unprocessed element
    uint256 private head;

    /// @notice The minimum amount of time a delayed publication needs to
    /// wait in the queue to be included expressed in seconds
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

    /// @inheritdoc IDelayedInclusionStore
    /// @dev Stores the blob reference as a DueInclusion
    function publishDelayed(uint256[] calldata blobIndices) external {
        bytes32 refHash = keccak256(abi.encode(blobRefRegistry.getRef(blobIndices)));
        DueInclusion memory dueInclusion = DueInclusion(refHash, block.timestamp + inclusionDelay);
        delayedInclusions.push(dueInclusion);
        emit DelayedInclusionStored(msg.sender, dueInclusion);
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

        // We only check msg.sender here to avoid the gas cost when the
        // return is empty and there are no state changes
        require(msg.sender == inbox, "Only inbox can process inclusions");

        Inclusion[] memory inclusions = new Inclusion[](count);
        for (uint256 i = 0; i < count; ++i) {
            inclusions[i] = Inclusion(delayedInclusions[head + i].blobRefHash);
        }

        emit DelayedInclusionProcessed(inclusions);

        // Move the head pointer forward.
        head = l;

        return inclusions;
    }
}
