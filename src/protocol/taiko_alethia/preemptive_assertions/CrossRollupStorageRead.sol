// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {PreemptiveProvableAssertionsBase} from "./PreemptiveProvableAssertionsBase.sol";

struct CrossRollupStorageRef {
    uint8 rollupChainId;
    address addr;
    uint256 slot;
}

/// @notice Assert a claimed storage value on another rollup at publication time
///   Note the indirection. This does not assert and prove the storage value, rather a (staked) claim.
///
/// This can be used for cross-rollup atomic execution, using the same pattern described in `L2QueryFutureBlock.sol`
/// except:
/// - the "future block" must be publication time
/// - the different transactions can occur on different rollups
/// - the guarantee is weaker
///
/// Consider the scenario:
/// - there are two based rollups (A and B) using this stack
/// - they choose their sequencers independently and without coordination
///     - L1 proposers can opt in to sequence each rollup under whatever conditions required by each rollup
/// - sometimes both rollups will happen to have the same sequencer for a particular slot
///
/// In this scenario, we want to allow the common sequencer to provide cross-rollup atomic execution
/// (where a transaction on rollup A only succeeds if a different transaction on rollup B also succeeds)
/// However, this implies a rollup A node cannot know the result of the rollup A transaction until they know if the
/// rollup B transaction succeeded. This means the next rollup A sequencer that does not run a rollup B node will be
/// unable to progress the chain. Without real-time proving or a shared sequencer for all participating rollups, this
/// seems insurmountable.
///
/// Instead, this contract provides a compromise that may be acceptable in some scenarios.
///
/// This contract assumes the following design changes will be made (which are probably desirable regardless):
/// - proposers post the final L2 block hash along with every publication.
/// - if the hash is incorrect, the whole publication is a no-op
/// - if the hash is incorrect, the proposer's preconfirmation-stake is slashed
/// - there is a coordination mechanism on L1 so that both rollup publications record both posted L2 block hashes
///
/// This means that after every publication on L1:
/// - the new state is either the claimed value or it is unchanged
/// - if it is not the claimed state, the proposer loses all transaction fees from their publication and is slashed
///
/// When the proposer knows the publication-time value of a storage slot on rollup B, they can assert this on rollup A.
/// Similar to the L1QueriesPublicationTime contract, this is probably most suitable for slots that are set and will not
/// change. However, since the proposer has complete control of the rollup B transactions, they can be more flexible.
///
/// Strictly speaking, they will assert the value of a storage slot with respect to the claimed rollup B block hash.
/// The claimed hash will be available on L1 at publication time, whether or not it matches the actual rollup B state.
/// In contrast to the other assertions, this does introduce a potential incentive to lie. If the proposer makes an
/// invalid claim for rollup B's block hash, but correctly asserts storage properties *about the claim* on rollup A:
/// - the rollup B publication will be a no-op, and
/// - the proposer will be slashed, but
/// - the rollup A publication will be valid, since the proposer can successfully prove assertions about the claim.
/// - rollup A transactions that depend on the rollup B assertions will execute under the wrong assumption.
/// If we proceed with this mechanism, we should consider how to ensure the proposer's stake and loss of transaction
/// fees exceeds the potential economic damage they may cause by posting an invalid rollup B claim.
abstract contract CrossRollupStorageRead is PreemptiveProvableAssertionsBase {
    bytes32 constant CROSS_ROLLUP_DOMAIN_SEPARATOR = keccak256("CrossRollupStorageRead");

    function getCrossRollupStorage(CrossRollupStorageRef memory ref) public view returns (uint256) {
        bytes32 assertionId = _assertionId(ref);
        require(exists[assertionId], "Cross rollup storage has not been asserted");
        return value[assertionId];
    }

    function assertCrossRollupStorage(CrossRollupStorageRef memory ref, uint256 value) public onlyAsserter {
        _assert(_assertionId(ref), value);
    }

    function _proveCrossRollupStorage(
        bytes32[] memory blockHashClaims,
        CrossRollupStorageRef[] memory refs,
        uint256[] memory values,
        bytes memory proof
    ) internal {
        // TODO: Use the proof to validate all the asserted refs/values correspond to the blockHashClaims
        // There is a subtlety here. Each block hash (and therefore the attribute that contains the block hashes)
        // represents all transactions in the publication, including endPublication. This means the attribute hash
        // passed to this call is derived after this call. I suspect that this is fine because we know endPublication
        // simply deletes the assertions, so we can predict its final state anyway. I do not know if that logic extends
        // to the gas accounting, partly because I'm not sure if the anchor transaction / end publication transactions
        // actually update the gas used, and even if they did, the actual operations that the call will take are known
        // even though the particular input hash is not. If this proves to be unworkable, we can require the claim to be
        // the state root before endPublication rather than the block hash after it.
        for (uint256 i = 0; i < refs.length; i++) {
            _resolve(_assertionId(refs[i]));
        }
    }

    function _assertionId(CrossRollupStorageRef memory ref) private pure returns (bytes32) {
        return keccak256(abi.encode(CROSS_ROLLUP_DOMAIN_SEPARATOR, ref));
    }
}
