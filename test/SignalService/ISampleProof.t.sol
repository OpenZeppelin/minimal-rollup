// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISignalService} from "src/protocol/ISignalService.sol";

interface ISampleProof {
    function getSignalServiceAddress() external returns (address);

    function getSignalProof() external returns (ISignalService.SignalProof memory);

    function getSignalDetails() external returns (address sender, bytes32 value);

    function getSlot() external returns (bytes32 slot);
}
