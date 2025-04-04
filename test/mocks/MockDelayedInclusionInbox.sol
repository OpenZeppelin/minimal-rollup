//// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {ILookahead} from "src/protocol/ILookahead.sol";
import {IProposerFees} from "src/protocol/IProposerFees.sol";
import {IPublicationFeed} from "src/protocol/IPublicationFeed.sol";
import {DelayedInclusionStore} from "src/protocol/taiko_alethia/DelayedInclusionStore.sol";
import {TaikoInbox} from "src/protocol/taiko_alethia/TaikoInbox.sol";

/// @dev A mock contract for testing delayed inclusion functionality.
contract MockTaikoInbox is TaikoInbox {
    constructor(
        address _publicationFeed,
        address _lookahead,
        address _blobRefRegistry,
        uint256 _maxAnchorBlockIdOffset,
        address _proposerFees,
        uint256 _inclusionDelay
    )
        TaikoInbox(_publicationFeed, _lookahead, _blobRefRegistry, _maxAnchorBlockIdOffset, _proposerFees, _inclusionDelay)
    {}

    /// @dev Exposes the internal processDueInclusions function for testing purposes
    function processDueInclusionsExternal() external returns (Inclusion[] memory) {
        Inclusion[] memory inclusions = processDueInclusions();
        return inclusions;
    }
}
