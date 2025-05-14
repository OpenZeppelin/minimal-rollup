// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

interface ISampleDepositProof {
    function getSourceAddresses() external returns (address signalService, address bridge);
    function getDepositSignalProof() external returns (ISignalService.SignalProof memory);
    function getEthDeposit() external pure returns (IETHBridge.ETHDeposit memory deposit);
    function getDepositInternals() external pure returns (bytes32 slot, bytes32 id);
}
