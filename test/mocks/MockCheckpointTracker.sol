// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICheckpointTracker} from "src/protocol/ICheckpointTracker.sol";

contract MockCheckpointTracker is ICheckpointTracker {
    error InvalidProof();

    // Return a hardcoded value. Different scenarios can be tested by using different
    // publications/checkpoints relative to this one.
    uint256 public provenPublicationId = 10;

    // Mock values. They are public so they can be queried
    bool public valid = true;
    uint256 public nPublications = 3;
    uint256 public nDelayedPublications = 1;

    function proveTransition(Checkpoint calldata, Checkpoint calldata, bytes calldata)
        external
        view
        returns (uint256, uint256)
    {
        if (!valid) revert InvalidProof();
        return (nPublications, nDelayedPublications);
    }

    function setValid(bool isValid) external {
        valid = isValid;
    }

    function setNumPublications(uint256 _nPublications, uint256 _nDelayedPublications) external {
        nPublications = _nPublications;
        nDelayedPublications = _nDelayedPublications;
    }
}
