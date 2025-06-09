// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Asserter} from "./Asserter.sol";

contract FutureL2Call is Asserter {
    
    constructor(address _anchor, address _preemptiveAssertions) Asserter(_anchor, _preemptiveAssertions) {}

    function assertFutureCall(
        uint256 l2BlockNumber,
        address destination,
        bytes calldata callData,
        bytes calldata returnData
    ) external {
        preemptiveAssertions.createAssertion(_key(l2BlockNumber, destination, callData), keccak256(returnData));
    }

    function resolveCall(
        uint256 l2BlockNumber,
        address destination,
        bytes calldata callData
    ) external {
        require(block.number == l2BlockNumber, "Incorrect L2 block");
        bytes32 key = _key(l2BlockNumber, destination, callData);
        bytes32 assertedReturnHash = preemptiveAssertions.getAssertion(key);

        (bool success, bytes memory returnData) = destination.call(callData);
        require(success, "Call failed");
        require(assertedReturnHash == keccak256(returnData), "Incorrect return data");

        preemptiveAssertions.removeAssertion(key);
    }

   
    function _key(uint256 l2BlockNumber, address destination, bytes calldata callData) internal pure returns (bytes32) {
        return keccak256(abi.encode(l2BlockNumber, destination, callData));
    }

    /// @dev This contract does not require coordination with L1, so it does not need the Asserter functionality
    /// It is included anyway for structural clarity, but this function reverts to disable the behavior.
    function _resolve(bytes32[] calldata, bytes calldata) internal pure override {
        assert(false);
    }

}
