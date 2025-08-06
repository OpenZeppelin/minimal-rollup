// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IInbox} from "src/protocol/IInbox.sol";

/// @notice Mock implementation of IInbox for testing
contract MockInbox is IInbox {
    // Start at 1 so there is always a previous hash
    uint256 private numPublications = 1;

    mapping(bytes32 headerHash => bool) private isInvalid;

    error NotImplemented();

    function publish(uint256, uint64) external pure {
        revert NotImplemented();
    }

    function updateProposerFees(address) external pure {
        revert NotImplemented();
    }

    function getPublicationHash(uint256 id) external view returns (bytes32) {
        if (id >= numPublications) return 0;
        return keccak256(abi.encode("MockInbox", id));
    }

    function getNextPublicationId() external view returns (uint256) {
        return numPublications;
    }

    function validateHeader(PublicationHeader calldata header) external view returns (bool) {
        return !isInvalid[keccak256(abi.encode(header))];
    }

    // Mock functionality

    function setInvalidHeader(PublicationHeader calldata header) external {
        isInvalid[keccak256(abi.encode(header))] = true;
    }

    function publishMultiple(uint256 count) external {
        numPublications += count;
    }
}
