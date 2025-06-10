// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {CalledByAnchor} from "./CalledByAnchor.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract PublicationPauser is Pausable, CalledByAnchor {
    address private pauser = address(0);

    error CallerIsNotPauser();
    error PauserIsAlreadySet();

    constructor() {
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

    function pause() external onlyPauser {
        _pause();
    }

    function unpause() external onlyPauser {
        _unpause();
    }

    function removePauser() external onlyAnchor {
        pauser = address(0);
    }
}
