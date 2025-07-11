// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IVerifier} from "src/protocol/IVerifier.sol";

contract MockVerifier is IVerifier {
    bool private validProof = true;

    error VerificationFailed();

    function verifyProof(
        bytes32, /* startPublicationHash */
        bytes32, /* endPublicationHash */
        bytes32, /* startCheckPoint */
        bytes32, /* endCheckPoint */
        bytes32, /* intermediateCheckPoint */
        uint256, /* numDelayedPublications */
        bytes calldata /* proof */
    ) external view {
        require(validProof, VerificationFailed());
    }

    function setValidity(bool isValid) external {
        validProof = isValid;
    }
}
