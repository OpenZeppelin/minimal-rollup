// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ITaikoData {
    struct DataSource {
        bytes32[] blobs;
    }

    struct Proposal {
        bytes32 anchorBlockhash;
        DataSource[] proposalDataList;
    }
}
