// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IProposerFees} from "../../src/protocol/IProposerFees.sol";

/// @title MockProposerFees
/// @notice A mock implementation of the IProposerFees interface for testing and development
contract MockProposerFees is IProposerFees {
    function payPublicationFee(address proposer, bool isDelayed) external override {}

    /// @notice Returns the current fees
    /// @return fee The fee for a regular publication
    /// @return delayedFee The fee for a delayed publication
    function getCurrentFees() external view override returns (uint96 fee, uint96 delayedFee) {
        return (0, 0);
    }
}
