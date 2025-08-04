// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {SampleProof} from "./SampleProof.t.sol";
import {SignalService} from "src/protocol/SignalService.sol";

contract InitialState is Test {
    SignalService signalService;
    SampleProof sampleProof;

    function setUp() public virtual {
        sampleProof = new SampleProof();

        // The SignalService on this chain should be at the same address as the source chain.
        signalService = SignalService(sampleProof.getSignalServiceAddress());
        deployCodeTo("SignalService.sol", address(signalService));
    }
}
