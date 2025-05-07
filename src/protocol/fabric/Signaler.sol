// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISignalService} from "../../signal/ISignalService.sol";
import {ISignaler} from "./ISignaler.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract Signaler is ISignaler {
    address private _signalService;
    uint256 private _nonce;

    /**
     * @notice Executes a batch of calls initiated by the account owner.
     * @param calls An array of Call structs containing destination, ETH value, and calldata.
     */
    function executeBatch(Call[] calldata calls) external {
        if (msg.sender != address(this)) revert NotOwner();
        _executeBatch(calls);
    }

    /**
     * @notice Executes a batch of calls using an off–chain signature.
     * @param calls An array of Call structs containing destination, ETH value, and calldata.
     * @param signature The ECDSA signature over the current nonce and the call data.
     *
     * The signature must be produced off–chain by signing:
     * The signing key should be the account's key (which becomes the smart account's own identity after upgrade).
     */
    function executeBatchWithSig(Call[] calldata calls, bytes calldata signature) external {
        // Compute the digest that the account was expected to sign.
        bytes memory encodedCalls;
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }
        bytes32 digest = keccak256(abi.encodePacked(_nonce, encodedCalls));

        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(digest);

        // Recover the signer from the provided signature.
        address recovered = ECDSA.recover(ethSignedMessageHash, signature);
        if (recovered != address(this)) revert InvalidSignature();

        _executeBatch(calls);
    }

    function setSignalService(address signalService_) external {
        if (msg.sender != address(this)) revert NotOwner();
        _signalService = signalService_;
    }

    // Allow the contract to receive ETH
    fallback() external payable {}
    receive() external payable {}

    // internal functions
    function _executeBatch(Call[] calldata calls) internal {
        uint256 currentNonce = _nonce;
        _nonce++; // Increment nonce to protect against replay attacks

        for (uint256 i = 0; i < calls.length; i++) {
            _executeCall(calls[i]);
        }

        emit BatchExecuted(currentNonce, calls);
    }

    function _executeCall(Call calldata call) internal {
        (bool success, bytes memory returnData) = call.to.call{value: call.value}(call.data);
        if (!success) revert CallReverted();

        // Hash the inputs and outputs of the call
        bytes32 signal = _hashSignal(call, returnData);

        // Send the signal to the signal service contract
        _sendSignal(signal);

        emit CallExecuted(msg.sender, call.to, call.value, call.data);
    }

    function _sendSignal(bytes32 signal) internal returns (bytes32 slot) {
        return ISignalService(_signalService).sendSignal(signal);
    }

    function _hashSignal(Call calldata callData, bytes memory output) internal pure returns (bytes32) {
        bytes32 signal = keccak256(abi.encode(callData, output));
        return signal;
    }

    // view functions
    function signalService() external view returns (address) {
        return _signalService;
    }

    function nonce() external view returns (uint256) {
        return _nonce;
    }
}
