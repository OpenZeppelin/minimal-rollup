// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {EssentialContract} from "../common/EssentialContract.sol";
import {LibStrings} from "../common/LibStrings.sol";
import {IERC7786GatewaySource} from "./IERC7786.sol";
import {ISignalService} from "./ISignalService.sol";
import {CAIP10} from "@openzeppelin/contracts/utils/CAIP10.sol";
import {CAIP2} from "@openzeppelin/contracts/utils/CAIP2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Implementation of an ERC-7786 gateway source adapter for the Taiko Network.
 *
 * The contract provides a way to send messages to a remote chain via the Taiko Network
 * using the {sendMessage} function.
 */
abstract contract TaikoGatewaySource is IERC7786GatewaySource, EssentialContract {
    using Strings for address;

    error UnsupportedNativeTransfer();

    /// @inheritdoc IERC7786GatewaySource
    function supportsAttribute(bytes4 /*selector*/ ) public pure returns (bool) {
        return false;
    }

    /// @inheritdoc IERC7786GatewaySource
    function sendMessage(
        string calldata destinationChain, // CAIP-2 chain identifier
        string calldata receiver, // CAIP-10 account address (does not include the chain identifier)
        bytes calldata payload,
        bytes[] calldata attributes
    ) external payable returns (bytes32 outboxId) {
        require(msg.value == 0, UnsupportedNativeTransfer());
        // Use of `if () revert` syntax to avoid accessing attributes[0] if it's empty
        if (attributes.length > 0) {
            revert UnsupportedAttribute(attributes[0].length < 0x04 ? bytes4(0) : bytes4(attributes[0][0:4]));
        }

        // Create the package
        string memory sender = msg.sender.toChecksumHexString();

        // Emit event
        outboxId = bytes32(0); // Explicitly set to 0
        emit MessagePosted(
            outboxId,
            CAIP10.format(CAIP2.local(), sender),
            CAIP10.format(destinationChain, receiver),
            payload,
            attributes
        );

        // Hash the adapterPayload to create a fixed-length bytes32
        bytes memory adapterPayload = abi.encode(sender, receiver, payload, attributes);
        bytes32 signal = keccak256(adapterPayload);

        // Send the message
        ISignalService(resolve(LibStrings.B_SIGNAL_SERVICE, false)).sendSignal(signal);

        return outboxId;
    }
}
