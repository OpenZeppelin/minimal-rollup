// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {UniversalTest} from "./UniversalTest.t.sol";

import {LibSignal} from "src/libs/LibSignal.sol";

import {IETHBridge} from "src/protocol/IETHBridge.sol";
import {ISignalService} from "src/protocol/ISignalService.sol";

/// This contract describes behaviours that should be valid when a cross chain deposit exists.
/// This implies a deposit was made on the counterpart bridge (on another chain) and the commitment
/// was stored on this chain's signal service.
/// We use the SampleDepositProof contract to track the deposit details.
/// @dev The contract is abstract because it should be specialised into the cases where the bridge
/// does or does not have sufficient ether
abstract contract CrossChainDepositExists is UniversalTest {
    // the sample deposit is to this address
    address recipient = _randomAddress("recipient");

    uint256 HEIGHT = 1;

    function setUp() public virtual override {
        super.setUp();
        bytes32 commitment =
            keccak256(abi.encodePacked(sampleDepositProof.getStateRoot(), sampleDepositProof.getBlockHash()));
        vm.prank(trustedCommitmentPublisher);
        signalService.storeCommitment(HEIGHT, commitment);
    }

    // This is just a sanity-check.
    // It does not test any contract behaviour but just validates consistency with the sample proofs
    function test_depositInternals() public view {
        uint256 nProofs = sampleDepositProof.getNumberOfProofs();
        for (uint256 i = 0; i < nProofs; i++) {
            IETHBridge.ETHDeposit memory deposit = sampleDepositProof.getEthDeposit(i);
            (bytes32 slot, bytes32 id) = sampleDepositProof.getDepositInternals(i);

            assertEq(bridge.getDepositId(deposit), id, "deposit id mismatch");
            assertEq(LibSignal.deriveSlot(id, counterpart), slot, "slot mismatch");
        }
    }

    // Returns a deposit with a non-zero amount and no data field
    // It can be overriden to re-run tests with a different deposit
    function _depositIdx() internal pure virtual returns (uint256) {
        return 0;
    }
}
