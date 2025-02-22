// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISignalService} from "./ISignalService.sol";
import {StatelessMmr} from "solidity-mmr/lib/StatelessMmr.sol";

///@title SignalService
///@notice An implementation of the ISignalService interface using Merkle Mountain Ranges (MMR).
contract SignalService is ISignalService {
    uint256 private _count;
    bytes32 private _root;
    bytes32[] private _peaks;

    ///@inheritdoc ISignalService
    function send(bytes32 signal) external {
        (uint256 count, bytes32 root, bytes32[] memory peaks) =
            StatelessMmr.appendWithPeaksRetrieval(signal, _peaks, _count, _root);

        // The new count is the signal's index
        emit Signal(signal, count, block.number);
        (_peaks, _count, _root) = (peaks, count, root);
    }

    /// @inheritdoc ISignalService
    function verify(uint256 idx, bytes32 signal, bytes32[] memory proof) external view {
        StatelessMmr.verifyProof(idx, signal, proof, _peaks, _count, _root);
    }

    /// @notice Returns the current MMR root
    /// @return The current MMR root
    function getRoot() external view returns (bytes32) {
        return _root;
    }

    /// @notice Returns the current MMR peaks
    /// @return The current MMR peaks
    function getPeaks() external view returns (bytes32[] memory) {
        return _peaks;
    }

    /// @notice Returns the current number of signals
    /// @return The current number of signals
    function getCount() external view returns (uint256) {
        return _count;
    }
}
