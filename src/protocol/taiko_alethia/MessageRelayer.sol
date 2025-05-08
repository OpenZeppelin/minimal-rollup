// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";
import {MessageRelayer} from "src/protocol/taiko_alethia/MessageRelayer.sol";

/// @dev Simple implementation of a message relayer.
///
/// Relays messages from the bridge to the receiver and handles fees.
///
/// Example message:
///    If Alice wants to send herself 1 eth to L2 with a fee of 0.1 eth.
///
///    ETHDeposit {
///    nonce: 0,
///    from: msg.sender,
///    to: address(MessageRelayer),
///    amount: 1.1 eth,
///    data: encodedData
///    }
///
///    Where encodedData is roughly:
///        abi.encodeWithSignature(
///            "receiveMessage(address,uint256,uint256,bytes)",
///             address(Alice),
///             0.1 eth (fee for the relayer),
///             0 (gas limit),
///             data (in this case ""),
///             )
///
/// If relayer wants to claim this fee, it needs to call claimDeposit on the bridge.
/// The relayer will net any fee - gas spent on the call to relayMessage.
contract MessageRelayer is ReentrancyGuardTransient, IMessageRelayer {
    using TransientSlot for *;

    IETHBridge public immutable ethBridge;

    constructor(address _ethBridge) {
        ethBridge = IETHBridge(_ethBridge);
    }

    // keccak256("RELAYER_SLOT")
    bytes32 private constant RELAYER_SLOT = 0x534e7df1601a31e65156f390f0558b27c1017ac64f70cc962aaaeb10ce90ea23;

    /// @inheritdoc IMessageRelayer
    function relayMessage(
        IETHBridge.ETHDeposit memory ethDeposit,
        uint256 height,
        bytes memory proof,
        address relayerAddress
    ) external {
        RELAYER_SLOT.asAddress().tstore(relayerAddress);

        ethBridge.claimDeposit(ethDeposit, height, proof);

        emit RelayInitiated(ethDeposit, relayerAddress);
    }

    /// @inheritdoc IMessageRelayer
    function receiveMessage(address to, uint256 fee, uint256 gasLimit, bytes memory data)
        external
        payable
        nonReentrant
    {
        address relayer = RELAYER_SLOT.asAddress().tload();

        uint256 valueToSend = msg.value - fee;
        bool success;

        if (gasLimit == 0) {
            (success,) = to.call{value: valueToSend}(data);
        } else {
            require(gasLimit <= gasleft(), InsufficientGasLimit());
            (success,) = to.call{value: valueToSend, gas: gasLimit}(data);
        }

        require(success, MessageForwardingFailed());

        payable(relayer).transfer(fee);

        emit MessageForwarded(to, valueToSend, data);

        RELAYER_SLOT.asAddress().tstore(address(0));
    }
}
