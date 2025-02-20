// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ITaikoData} from "./TaikoPublicationHook.sol";

interface IDelayedInclusionStore {
    function processDelayedInclusionByDeadline(uint256 deadline)
        external
        returns (ITaikoData.ProposalData[] memory proposalDataList);
}
