// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IBondManager {
    /// @notice Calculates the required bond amount for a new checkpoint proposal
    /// @dev Currently, we don't have the info on how many blocks are being proposed as part of a single publication.
    ///      So we can't use that information to calculate the bond. Should we add that info?
    /// @param proposer The address attempting to propose the checkpoint
    /// @param publicationIdx The index of the publication being proposed
    /// @return bondAmount The required bond amount in wei
    function calculateLivenessBond(address proposer, uint256 publicationIdx)
        external
        view
        returns (uint256 bondAmount);

    /// @notice Locks the specified bond amount from the proposer's balance
    /// @param proposer The address proposing the checkpoint
    /// @param bondAmount The amount to lock in wei
    function debitBond(address proposer, uint256 bondAmount) external;

    /// @notice Returns who is the "designated prover" for the given publication. For example,
    ///      an auction-based BondManager might decide that only the winner can prove.
    /// @dev If proving is permissionless, this function should return the zero address.
    /// @param publicationIdx The index of the publication
    /// @return The address of the designated prover, or zero address if proving is permissionless
    function getDesignatedProver(uint256 publicationIdx) external view returns (address);

    /// @dev Credits (unlocks) all or part of the bond. This might be a full refund to the proposer,
    ///      or a partial distribution to the prover. It's up to the BondManager logic to decide
    ///      how that is split.
    /// @param prover The address that actually submitted the proof.
    /// @param proposer The address that originally proposed the checkpoint.
    /// @param bondAmount The total bond that was previously locked.
    function creditBond(address prover, address proposer, uint256 bondAmount) external;

    /// @notice Allows users to withdraw a part of their unlocked bond amount
    /// @param recipient The address to receive the withdrawn amount
    /// @param amount The amount to withdraw in wei
    function withdraw(address recipient, uint256 amount) external;
}
