// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IInbox} from "src/protocol/IInbox.sol";

/// @notice Mock implementation of IInbox for testing
contract MockInbox is IInbox {
    mapping(bytes32 headerHash => bool) private isInvalid;

    error NotImplemented();

    function publish(uint256, uint64) external pure {
        revert NotImplemented();
    }

    function getPublicationHash(uint256) external pure returns (bytes32) {
        revert NotImplemented();
    }

    function getNextPublicationId() external pure returns (uint256) {
        revert NotImplemented();
    }

    function validateHeader(PublicationHeader calldata header) external view returns (bool) {
        return !isInvalid[keccak256(abi.encode(header))];
    }

    function setInvalidHeader(PublicationHeader calldata header) external {
        isInvalid[keccak256(abi.encode(header))] = true;
    }
}
