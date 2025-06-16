// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CrossChainDepositExists} from "./CrossChainDepositExists.t.sol";

/// This contract describes behaviours that should be valid when the local bridge has
/// enough ether to cover the cross chain deposit.
/// On L1, this would be from a previous deposit (to the L2).
/// On L2, we assume the bridge is prefunded.
abstract contract BridgeSufficientlyCapitalized is CrossChainDepositExists {
    function setUp() public virtual override {
        super.setUp();
        vm.deal(address(bridge), sampleDepositProof.getEthDeposit(_depositIdx()).amount);
    }
}

/// This contract describes behaviours that should be valid when the local bridge does
/// not have any Ether to cover the cross chain deposit.
/// This should not happen during normal operations because:
/// - on L1, the bridge should hold all ETH that was deposited to L2 so any valid cross-chain deposit must use L2 ETH
/// that was originally deposited to this bridge.
/// - on L2, the bridge should be prefunded with enough ETH to cover all L1 ETH.
/// A technicality: the bridge can be used to send a message without sending ETH, in which case this case
/// is still sufficiently capitalized.
abstract contract BridgeHasNoEther is CrossChainDepositExists {
// no need to do anything because the bridge defaults to zero balance
// this contract only exists to help describe the scenario
}
