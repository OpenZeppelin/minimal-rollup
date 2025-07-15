// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";
import {IETHBridge} from "src/protocol/IETHBridge.sol";

import {IMessageRelayer} from "src/protocol/IMessageRelayer.sol";

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
///    data: encodedData,
///    context: bytes(0) // this relayer does not use this field
///    }
///
///    Where encodedData is roughly:
///        abi.encodeCall(
///            IMessageRelayer.receiveMessage,
///            (
///                address(Alice),    // to
///                0.1 ether,        // tip for the relayer
///                address(tipRecipient) // specified tip recipient
///                0,                // gas limit
///                ""                // data (in this case empty)
///            )
///        )
///
/// To relay the message:
///    1. Trigger the relay:
///      a) If the tip recipient is specified in the ETHDeposit, the relayer can call `ETHBridge.claimDeposit` directly.
///      b) Otherwise, anyone can pass a tip recipient to `relayMessage`, which will then call `ETHBridge.claimDeposit`.
///         Note that the provided recipient will be ignored if it already specified.
///      Relayers should ensure the tip they receive is sufficient compensation for the gas spent on this call.
///    2. If the original message was specified correctly, `claimDeposit` will invoke `receiveMessage` on this contract.
///    3. This will call the message recipient and send the tip to the tip recipient.
///
/// WARN: There is no relayer protection. In particular
/// - if the ETHDeposit does not invoke `receiveMessage`, the tip recipient will not be paid.
/// - if a relayer calls `claimDeposit` directly (case 1a above) but no recipient is specified, the tip will be sent
///   to whichever address happens to be stored in the `TIP_RECIPIENT_SLOT` (including address(0)).
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
    /// @dev `ETHBridge.claimDeposit` should be called instead if the tip recipient is specified in the `ethDeposit`.
    function relayMessage(
        IETHBridge.ETHDeposit memory ethDeposit,
        uint256 height,
        bytes memory proof,
        address tipRecipient
    ) external {
        TIP_RECIPIENT_SLOT.asAddress().tstore(tipRecipient);

        ethBridge.claimDeposit(ethDeposit, height, proof);
    }

    /// @inheritdoc IMessageRelayer
    function receiveMessage(address to, uint256 tip, address tipRecipient, uint256 gasLimit, bytes memory data)
        external
        payable
        nonReentrant
    {
        // If none specified use the one in temporary storage
        if (tipRecipient == address(0)) {
            tipRecipient = TIP_RECIPIENT_SLOT.asAddress().tload();
        }

        uint256 valueToSend = msg.value - tip;
        bool forwardMessageSuccess;

        if (gasLimit == 0) {
            (forwardMessageSuccess,) = to.call{value: valueToSend}(data);
        } else {
            // EIP-150: Only 63/64 of gas can be forwarded to external calls.
            // Check against actual forwardable gas with buffer for operations before the call.
            uint256 maxForwardableGas = (gasleft() - BUFFER) * 63 / 64;
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
