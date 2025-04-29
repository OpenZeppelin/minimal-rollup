// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SignalService} from "./SignalService.sol";

contract L2SignalService is SignalService {

    address immutable L1_CHECKPOINT_TRACKER;

    constructor(address _l1CheckpointTracker) {
        L1_CHECKPOINT_TRACKER = _l1CheckpointTracker;
    }


    function _isValidDeposit(ETHDeposit memory ethDeposit) internal override returns (bool) {
        // Only accept deposits that were intended for this chain
        return ethDeposit.releaseAuthority == L1_CHECKPOINT_TRACKER;
    }
}