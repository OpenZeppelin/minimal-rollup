// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract PublicationPauser is Pausable {
    address private pauser = address(0);
    address private immutable anchor;

    error CallerIsNotPauser();
    error PauserIsAlreadySet();
    error CallerIsNotAnchor();

    constructor(address _anchor) {
        anchor = _anchor;
        _pause(); // Start in paused state
    }

    modifier onlyPauser() {
        require(msg.sender == pauser, CallerIsNotPauser());
        _;
    }

    /// @dev There is no access control. The sequencer should ensure it is called with a trusted address.
    function setPauser(address _pauser) external {
        require(pauser == address(0), PauserIsAlreadySet());
        pauser = _pauser;
    }

    function removePauser() external {
        require(msg.sender == anchor, CallerIsNotAnchor());
        pauser = address(0);
    }

    function pause() external onlyPauser {
        _pause();
    }

    function unpause() external onlyPauser {
        _unpause();
    }
}
