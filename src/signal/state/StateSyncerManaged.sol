// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";

import {StateSyncer} from "./StateSyncer.sol";
import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";

/// @dev StateSyncer with a syncer role managed through an AccessManager authority.
contract StateSyncerManaged is StateSyncer, AccessManaged {
    uint64 internal constant STATE_SYNCER_ROLE = uint64(uint256(keccak256("Taiko.StateSyncer.Syncer")));

    /// @dev Sets the manager.
    constructor(address manager, address signalService_) AccessManaged(manager) StateSyncer(signalService_) {}

    /// @inheritdoc StateSyncer
    function _checkSyncer(address caller) internal virtual override {
        (bool member,) = IAccessManager(authority()).hasRole(STATE_SYNCER_ROLE, caller);
        require(member, AccessManagedUnauthorized(caller));
    }
}
