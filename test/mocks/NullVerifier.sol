// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IVerifier} from "src/protocol/IVerifier.sol";

contract NullVerifier is IVerifier {
    /// @notice Do nothing. All proofs are accepted.
    function verifyProof(
        bytes32, /* startPublicationHash */
        bytes32, /* endPublicationHash */
        bytes32, /* startCheckPoint */
        bytes32, /* endCheckPoint */
        uint256, /* numDelayedPublications */
        bytes calldata /* proof */
    ) external {}
}
