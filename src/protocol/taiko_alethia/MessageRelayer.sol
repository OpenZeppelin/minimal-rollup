// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";
import {MessageRelayer} from "src/protocol/taiko_alethia/MessageRelayer.sol";

/// @dev Simple implementation of a message relayer.
///
/// Relays messages from the bridge to the receiver and handles tips.
///
/// Example message:
///    If Alice wants to send herself 1 eth to L2 with a tip of 0.1 eth.
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
///        abi.encodeCall(
///            IMessageRelayer.receiveMessage,
///            (
///                address(Alice),    // to
///                0.1 ether,        // tip for the relayer
///                0,                // gas limit
///                ""                // data (in this case empty)
///            )
///        )
///
/// To relay the message:
///    1. Any address on the destination chain can call relayMessage
///    2. This will call claimDeposit on the ETHBridge
///    3. If the original message was specified correctly, this will call receiveMessage on this contract
///    4. This will call the message recipient and send the tip to the relayer
///
/// The relayer will net any tip minus the gas spent on the call to relayMessage.
///
/// WARN: There is no relayer protection. In particular:
///    - if the ETHDeposit does not invoke receiveMessage, the relayer will not be paid.
///    - if receiveMessage is called directly, the tip will be sent to whichever address exists in the
/// TIP_RECIPIENT_SLOT (typically address(0)).
contract MessageRelayer is ReentrancyGuardTransient, IMessageRelayer {
    using TransientSlot for *;

    IETHBridge public immutable ethBridge;

    constructor(address _ethBridge) {
        ethBridge = IETHBridge(_ethBridge);
    }

    // keccak256("TIP_RECIPIENT_SLOT")
    bytes32 private constant TIP_RECIPIENT_SLOT = 0x833ce1785f54a5ca49991a09a7b058587309bf3687e5f20b7b66fa12132ef6f0;
    // Buffer to make sure enough gas is forwarded to the external call.
    uint256 private constant BUFFER = 20_000;

    /// @inheritdoc IMessageRelayer
    /// @dev For relayer selection, encode the allowed relayer address in the context field of the ETHDeposit.
    /// If context is 20 bytes, it will be decoded as the allowed relayer address.
    /// Use address(0) or empty context to allow any relayer.
    function relayMessage(
        IETHBridge.ETHDeposit memory ethDeposit,
        uint256 height,
        bytes memory proof,
        address tipRecipient
    ) external {
        address allowedRelayer = address(0);
        if (ethDeposit.context.length == 20) {
            allowedRelayer = abi.decode(ethDeposit.context, (address));
        }
        require(allowedRelayer == address(0) || allowedRelayer == msg.sender, InvalidRelayer());

        TIP_RECIPIENT_SLOT.asAddress().tstore(tipRecipient);

        ethBridge.claimDeposit(ethDeposit, height, proof);
    }

    /// @inheritdoc IMessageRelayer
    function receiveMessage(address to, uint256 tip, uint256 gasLimit, bytes memory data)
        external
        payable
        nonReentrant
    {
        address tipRecipient = TIP_RECIPIENT_SLOT.asAddress().tload();

        uint256 valueToSend = msg.value - tip;
        bool forwardMessageSuccess;

        if (gasLimit == 0) {
            (forwardMessageSuccess,) = to.call{value: valueToSend}(data);
        } else {
            // EIP-150: Only 63/64 of gas can be forwarded to external calls.
            // Check against actual forwardable gas with buffer for operations before the call.
            uint256 maxForwardableGas = (gasleft() * 63 / 64) - BUFFER;
            require(gasLimit <= maxForwardableGas, InsufficientGas());
            (forwardMessageSuccess,) = to.call{value: valueToSend, gas: gasLimit}(data);
        }

        require(forwardMessageSuccess, MessageForwardingFailed());

        TIP_RECIPIENT_SLOT.asAddress().tstore(address(0));

        (bool tipCallSuccess,) = tipRecipient.call{value: tip}("");
        require(tipCallSuccess, TipTransferFailed());
        emit MessageForwarded(to, valueToSend, data, tipRecipient, tip);
    }
}
