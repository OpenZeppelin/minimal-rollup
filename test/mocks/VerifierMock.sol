// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IVerifier} from "../../src/protocol/IVerifier.sol";

contract VerifierMock is IVerifier {
    function verifyProof(
        bytes32 startPublicationHash,
        bytes32 endPublicationHash,
        bytes32 startCheckPoint,
        bytes32 endCheckPoint,
        bytes calldata proof
    ) external {}
}
