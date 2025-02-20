// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {EssentialContract} from "../common/EssentialContract.sol";

import {LibStrings} from "../common/LibStrings.sol";
import {IERC7786Receiver} from "./IERC7786.sol";
import {ISignalService} from "./ISignalService.sol";
import {CAIP2} from "@openzeppelin/contracts/utils/CAIP2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Implementation of an ERC-7786 gateway destination adapter for the Taiko Network.
 */
abstract contract TaikoGatewayDestination is EssentialContract {
    using Strings for address;
    using Strings for string;

    error ReceiverExecutionFailed();

    /**
     * @dev Execution of a cross-chain message.
     *
     * Proper CAIP-10 encoding of the message sender (including the CAIP-2 name of the origin chain can be found in
     * the message)
     */
    function processMessage(bytes calldata adapterPayload, bytes calldata _proof, string calldata sourceChain)
        internal
    {
        // Parse the package
        (string memory sender, string memory receiver, bytes memory payload, bytes[] memory attributes) =
            abi.decode(adapterPayload, (string, string, bytes, bytes[]));

        // Hash payload to get signal
        bytes32 signal = keccak256(adapterPayload);

        ISignalService(resolve(LibStrings.B_SIGNAL_SERVICE, false)).proveSignalReceived(
            CAIP2.parse(sourceChain), resolve(LibStrings.B_GATEWAY_SOURCE, false), signal, _proof
        );
        bytes4 result =
            IERC7786Receiver(receiver.parseAddress()).executeMessage(sourceChain, sender, payload, attributes);
        require(result == IERC7786Receiver.executeMessage.selector, ReceiverExecutionFailed());
    }
}
