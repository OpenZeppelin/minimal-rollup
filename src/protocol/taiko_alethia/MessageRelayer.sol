// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

contract MessageRelayer is ReentrancyGuardTransient {
    /* Example message:
        If Alice wants to send herself 1 eth to L2 with a fee of 0.1 eth.

        ETHDeposit {
            nonce: 0,
            from: msg.sender,
            to: address(MessagerRelayer),
            amount: 1.1 eth,
            data: encodedData
        }

        Where encodedData is roughly:
        abi.encodeWithSignature(
            "receiveMessage(to, fee, data)",
            address(Alice),
            data (in this case ""),
            0.1 eth (fee for the relayer)
        )

    If relayer wants to claim this fee, it needs to call claimDeposit on the bridge.
    The relayer will net any fee - gas spent on the call to relayMessage.
    */

    IETHBridge public immutable ethBridge;

    constructor(address _ethBridge) {
        ethBridge = IETHBridge(_ethBridge);
    }

    // keccak256("RELAYER_SLOT")
    bytes32 constant RELAYER_SLOT = 0x534e7df1601a31e65156f390f0558b27c1017ac64f70cc962aaaeb10ce90ea23;

    function relayMessage(
        IETHBridge.ETHDeposit memory ethDeposit,
        uint256 height,
        bytes memory proof,
        address relayerAddress
    ) external {
        // store address in transient storage
        bytes32 relayerAddressBytes = bytes32(uint256(uint160(relayerAddress)));

        assembly {
            tstore(RELAYER_SLOT, relayerAddressBytes)
        }

        ethBridge.claimDeposit(ethDeposit, height, proof);
    }

    function receiveMessage(address to, uint256 fee, bytes memory data) external payable nonReentrant {
        bytes32 relayerAddressBytes;

        assembly {
            relayerAddressBytes := tload(RELAYER_SLOT)
        }

        address relayer = address(uint160(uint256(relayerAddressBytes)));

        payable(relayer).transfer(fee);

        (bool success,) = to.call{value: msg.value - fee}(data);
        require(success, "Message forwarding failed");

        // TODO: Should we clear the transient storage here?
    }
}
