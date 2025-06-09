//// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {IInbox} from "src/protocol/IInbox.sol";
import {ILookahead} from "src/protocol/ILookahead.sol";
import {IProposerFees} from "src/protocol/IProposerFees.sol";
import {DelayedInclusionStore} from "src/protocol/taiko_alethia/DelayedInclusionStore.sol";

contract MockDelayedInclusionStore is DelayedInclusionStore {
    constructor(uint256 _inclusionDelay, address _blobRefRegistry)
        DelayedInclusionStore(_inclusionDelay, _blobRefRegistry)
    {}

    function processDueInclusionsExternal() external returns (Inclusion[] memory) {
        Inclusion[] memory inclusions = processDueInclusions();
        return inclusions;
    }
}
