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
///        abi.encodeCall(
///            IMessageRelayer.receiveMessage,
///            address(Alice),
///            0.1 eth (fee for the relayer),
///            0 (gas limit),
///            data (in this case ""),
///        )
///
/// To relay the message:
///    1. Any address on the destination chain can call relayMessage
///    2. This will call claimDeposit on the ETHBridge
///    3. If the original message was specified correctly, this will call receiveMessage on this contract
///    4. This will call the message recipient and send the fee to the relayer
///
/// The relayer will net any fee minus the gas spent on the call to relayMessage.
///
/// WARN: There is no relayer protection. In particular:
///    - if the ETHDeposit does not invoke receiveMessage, the relayer will not be paid.
///    - if receiveMessage is called directly, the fee will be sent to whichever address exists in the RELAYER_SLOT
/// (typically address(0)).
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

        emit Relayed(ethDeposit, relayerAddress);
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
            require(gasLimit <= gasleft(), InsufficientGas());
            (success,) = to.call{value: valueToSend, gas: gasLimit}(data);
        }

        require(success, MessageForwardingFailed());
        emit MessageForwarded(to, valueToSend, data);

        RELAYER_SLOT.asAddress().tstore(address(0));

        payable(relayer).transfer(fee);
    }
}
