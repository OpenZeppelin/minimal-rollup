// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IAccessManager} from "@openzeppelin/contracts/access/manager/IAccessManager.sol";

import {SignalService} from "./SignalService.sol";
import {AccessManaged} from "@openzeppelin/contracts/access/manager/AccessManaged.sol";

/// @dev SignalService with a receiver role managed through an AccessManager authority.
contract SignalServiceManaged is SignalService, AccessManaged {
    uint64 internal constant SIGNAL_RECEIVER_ROLE = uint64(uint256(keccak256("Taiko.SignalService.Receiver")));

    /// @dev Sets the manager.
    constructor(address manager) AccessManaged(manager) {}

    /// @inheritdoc SignalService
    function _checkReceiver(address caller) internal virtual override {
        (bool member,) = IAccessManager(authority()).hasRole(SIGNAL_RECEIVER_ROLE, caller);
        require(member, AccessManagedUnauthorized(caller));
    }
}
