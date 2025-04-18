// SPDX-License-Identifier: MIT

// Adapted from https://github.com/NethermindEth/Taiko-Preconf-AVS/blob/master/SmartContracts/src/libraries/EIP4788.sol
// Referenced from: https://ethresear.ch/t/slashing-proofoor-on-chain-slashed-validator-proofs/19421
pragma solidity ^0.8.28;

import {MerkleUtils} from "./MerkleUtils.sol";

library EIP4788 {
    struct ValidatorProof {
        // `Chunks` of the SSZ encoded validator
        bytes32[8] validator;
        // Index of the validator in the beacon state validator list
        uint256 validatorIndex;
        // Proof of inclusion of validator in beacon state validator list
        bytes32[] validatorProof;
        // Root of the validator list in the beacon state
        bytes32 validatorsRoot;
        // Proof of inclusion of validator list in the beacon state
        bytes32[] beaconStateProof;
        // Root of the beacon state
        bytes32 beaconStateRoot;
        // Proof of inclusion of beacon state in the beacon block
        bytes32[] beaconBlockProofForState;
        // Proof of inclusion of the validator index in the beacon block
        bytes32[] beaconBlockProofForProposerIndex;
    }

    function verifyValidatorProof(bytes32 beaconBlockRoot, ValidatorProof memory validatorProof)
        internal
        pure
        returns (bool)
    {
        // Validator is verified against the validator list in the beacon state
        bytes32 validatorHashTreeRoot = MerkleUtils.merkleize(validatorProof.validator);
        if (
            !MerkleUtils.verifyProof(
                validatorProof.validatorProof,
                validatorProof.validatorsRoot,
                validatorHashTreeRoot,
                validatorProof.validatorIndex
            )
        ) {
            return false;
        }

        if (
            !MerkleUtils.verifyProof(
                validatorProof.beaconStateProof, validatorProof.beaconStateRoot, validatorProof.validatorsRoot, 11
            )
        ) {
            return false;
        }

        // Beacon state is verified against the beacon block
        if (
            !MerkleUtils.verifyProof(
                validatorProof.beaconBlockProofForState, beaconBlockRoot, validatorProof.beaconStateRoot, 3
            )
        ) {
            return false;
        }

        // Validator index is verified against the beacon block
        if (
            !MerkleUtils.verifyProof(
                validatorProof.beaconBlockProofForProposerIndex,
                beaconBlockRoot,
                MerkleUtils.toLittleEndian(validatorProof.validatorIndex),
                1
            )
        ) {
            return false;
        }
        return true;
    }
}
