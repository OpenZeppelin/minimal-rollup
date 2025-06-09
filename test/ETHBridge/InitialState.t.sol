// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";

import {SampleDepositProof} from "./SampleDepositProof.t.sol";
import {ETHBridge} from "src/protocol/ETHBridge.sol";
import {SignalService} from "src/protocol/SignalService.sol";
import {MessageRelayer} from "src/protocol/taiko_alethia/MessageRelayer.sol";

abstract contract InitialState is Test {
    ETHBridge bridge;
    SignalService signalService;
    address counterpart;
    SampleDepositProof sampleDepositProof;
    // zero address means any relayer is allowed
    address anyRelayer = address(0);

    address trustedCommitmentPublisher = _randomAddress("trustedCommitmentPublisher");

    MessageRelayer messageRelayer;
    address tipRecipient;

    function setUp() public virtual {
        sampleDepositProof = new SampleDepositProof();

        // The SignalService on this chain should be at the same address as the source chain.
        signalService = SignalService(sampleDepositProof.getSignalServiceAddress());
        deployCodeTo("SignalService.sol", address(signalService));

        counterpart = sampleDepositProof.getBridgeAddress();
        bridge = new ETHBridge(address(signalService), trustedCommitmentPublisher, counterpart);
    }

    function _randomAddress(string memory name) internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encode(_domainSeparator(), name)))));
    }

    function _domainSeparator() internal pure returns (bytes32) {
        return keccak256("ETHBridge");
    }

    function getNonce() internal view returns (uint256) {
        return uint256(vm.load(address(bridge), bytes32(uint256(1))));
    }
}
