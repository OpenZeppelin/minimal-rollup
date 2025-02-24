// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IProverManager {
    /**
     * @notice Checks if `prover` is currently allowed to prove a publication
     *         transitioning from `startId` to `endId`.
     */
    function canProve(address prover, uint256 startId, uint256 endId) external view returns (bool);

    /**
     * @notice Called by the Checkpoint contract after a successful proof.
     *         This gives the incentives contract a chance to reward the prover
     *         and update internal accounting or slash the previous prover if needed.
     */
    function onProven(address prover, uint256 startId, uint256 endId) external;
}
