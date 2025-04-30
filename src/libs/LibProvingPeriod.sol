// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library LibProvingPeriod {
    struct Period {
        // SLOT 1
        address prover;
        uint96 stake;
        // SLOT 2
        // the fee that the prover is willing to charge for proving each publication
        uint96 fee;
        // the percentage (with two decimals precision) of the fee that is charged for delayed publications.
        uint16 delayedFeePercentage;
        // the timestamp of the end of the period. Default to zero while the period is open.
        uint40 end;
        // the time by which the prover needs to submit a proof
        uint40 deadline;
        // whether the proof came after the deadline
        bool pastDeadline;
    }
}