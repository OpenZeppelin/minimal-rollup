// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CurrentPeriodIsActive} from "./CurrentPeriodIsActive.t.sol";

/// @dev The FirstPeriodIsOngoing is one example where CurrentPeriodIsActive
contract FirstPeriodIsOngoing is CurrentPeriodIsActive {

    function setUp() public override {
        super.setUp();

        // Create a publication to trigger the new period
        vm.warp(vm.getBlockTimestamp() + 1);
        vm.prank(inbox);
        proverManager.payPublicationFee{value: INITIAL_FEE}(proposer, false);
    }

}