//// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IBlobRefRegistry} from "../../blobs/IBlobRefRegistry.sol";
import {IDelayedInclusionStore} from "../IDelayedInclusionStore.sol";

contract DelayedInclusionStore is IDelayedInclusionStore {
    // Stores all delayed inclusion requests
    Inclusion[] private delayedInclusions;

    uint256 private lastInclusionRequestTime;

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
        delayedInclusions.push(Inclusion(refHash));
    }

    /// @inheritdoc IDelayedInclusionStore
    /// @dev Only returns inclusions if the delay period has passed
    /// otherwise returns an empty array.
    /// @dev Can only be called by the inbox contract.
    function processDueInclusions() external returns (Inclusion[] memory) {
        require(msg.sender == inbox, "Only inbox can process inclusions");

        Inclusion[] memory _inclusions;
        if (block.timestamp - lastInclusionRequestTime < inclusionDelay) {
            return _inclusions;
        }

        lastInclusionRequestTime = block.timestamp;
        _inclusions = delayedInclusions;
        delete delayedInclusions;
        return _inclusions;
    }
}
