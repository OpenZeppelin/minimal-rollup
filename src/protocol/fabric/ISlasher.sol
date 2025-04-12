// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import { IBLS } from "./IBLS.sol";

interface ISlasher {
    /// @notice A Delegation message from a proposer's BLS key to a delegate's BLS and ECDSA key
    struct Delegation {
        /// The proposer's BLS public key
        IBLS.G1Point proposer;
        /// The delegate's BLS public key for Constraints API
        IBLS.G1Point delegate;
        /// The address of the delegate's ECDSA key for signing commitments
        address committer;
        /// The slot number the delegation is valid for
        uint64 slot;
        /// Arbitrary metadata reserved for future use
        bytes metadata;
    }

    /// @notice A delegation message signed by a proposer's BLS key
    struct SignedDelegation {
        /// The delegation message
        Delegation delegation;
        /// The signature of the delegation message
        IBLS.G2Point signature;
    }

    /// @notice A Commitment message binding an opaque payload to a slasher contract
    struct Commitment {
        /// The type of commitment
        uint64 commitmentType;
        /// The payload of the commitment
        bytes payload;
        /// The hash this Commitment is bound to
        uint64 requestHash;
        /// The address of the slasher contract
        address slasher;
    }

    /// @notice A commitment message signed by a delegate's ECDSA key
    struct SignedCommitment {
        /// The commitment message
        Commitment commitment;
        /// The signature of the commitment message
        bytes signature;
    }

    /// @notice Slash a proposer's BLS key for a given delegation
    /// @dev The URC will call this function to slash a registered operator if supplied with a valid commitment and evidence
    /// @param delegation The delegation message
    /// @param commitment The commitment message
    /// @param evidence Arbitrary evidence for the slashing
    /// @param challenger The address of the challenger
    /// @return slashAmountGwei The amount of Gwei slashed
    function slash(
        Delegation calldata delegation,
        Commitment calldata commitment,
        bytes calldata evidence,
        address challenger
    ) external returns (uint256 slashAmountGwei);

    /// @notice Slash an operator for a given commitment
    /// @dev The URC will call this function to slash a registered operator if supplied with a valid commitment and evidence. The assumption is that the operator has opted into the slasher protocol on-chain.
    /// @param commitment The commitment message
    /// @param evidence Arbitrary evidence for the slashing
    /// @param challenger The address of the challenger
    /// @return slashAmountGwei The amount of Gwei slashed
    function slashFromOptIn(Commitment calldata commitment, bytes calldata evidence, address challenger)
        external
        returns (uint256 slashAmountGwei);
}
