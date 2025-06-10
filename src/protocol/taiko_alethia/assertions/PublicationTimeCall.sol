// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Asserter} from "./Asserter.sol";
import {CalledByAnchor} from "./CalledByAnchor.sol";

struct CallSpecification {
    address destination;
    bytes callData;
}

contract PublicationTimeCall is Asserter {
    constructor(address _anchor, address _preemptiveAssertions)
        CalledByAnchor(_anchor)
        Asserter(_preemptiveAssertions)
    {}

    function assertPublicationTimeCall(
        CallSpecification calldata l1Call,
        CallSpecification calldata l2ConditionCheck,
        bytes calldata returnData
    ) external {
        preemptiveAssertions.createAssertion(_key(l1Call, l2ConditionCheck), keccak256(returnData));
    }

    function _resolve(bytes32[] calldata attributeHashes, bytes calldata proof) internal override {
        (CallSpecification[] memory l1Calls, bytes[] memory l1ReturnData, CallSpecification[] memory l2ConditionChecks)
        = abi.decode(proof, (CallSpecification[], bytes[], CallSpecification[]));

        bytes32[] memory returnHashes = new bytes32[](l1ReturnData.length);
        for (uint256 i = 0; i < l1ReturnData.length; ++i) {
            returnHashes[i] = keccak256(l1ReturnData[i]);
        }

        require(attributeHashes[3] == keccak256(abi.encode(l1Calls, returnHashes)), "Incorrect L1 calls");
        require(l1Calls.length == l2ConditionChecks.length, "Mismatched L1 calls and L2 condition checks");

        for (uint256 i = 0; i < l1Calls.length; ++i) {
            bytes32 assertedReturnHash = preemptiveAssertions.getAssertion(_key(l1Calls[i], l2ConditionChecks[i]));
            // pass the L1 return data to the L2 condition check function
            bytes memory combinedCalldata = abi.encodePacked(l2ConditionChecks[i].callData, l1ReturnData[i]);
            (bool success, bytes memory conditionReturnData) = l2ConditionChecks[i].destination.call(combinedCalldata);

            require(success, "L2 condition check failed");
            require(keccak256(conditionReturnData) == assertedReturnHash, "Condition was not asserted");
            preemptiveAssertions.removeAssertion(_key(l1Calls[i], l2ConditionChecks[i]));
        }
    }

    function _key(CallSpecification memory l1Call, CallSpecification memory l2ConditionCheck)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(l1Call, l2ConditionCheck));
    }
}
