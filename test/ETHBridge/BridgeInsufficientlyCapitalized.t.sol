// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CrossChainDepositExists} from "./CrossChainDepositExists.t.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

/// This contract describes behaviours that should be valid when the local bridge does
/// not have enough Ether to cover the cross chain deposit.
/// This should not happen during normal operations because:
/// - on L1, the bridge should hold all ETH that was deposited to L2 so any valid cross-chain deposit must use L2 ETH
/// that was originally deposited to this bridge.
/// - on L2, the bridge should be prefunded with enough ETH to cover all L1 ETH.
contract BridgeInsufficientlyCapitalized is CrossChainDepositExists {
    function test_claimDeposit_shouldRevert() public {
        IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(_depositIdx());
        bytes memory proof = abi.encode(sampleDepositProof.getDepositSignalProof(_depositIdx()));

        vm.expectRevert(IETHBridge.FailedClaim.selector);
        bridge.claimDeposit(deposit, HEIGHT, proof);
    }
}
