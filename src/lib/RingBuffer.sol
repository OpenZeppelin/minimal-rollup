// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {Panic} from "@openzeppelin/contracts/utils/Panic.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library RingBuffer {
    using Arrays for bytes32[];

    struct Checkpoint {
        /// @dev Maps checkpoints to an always increasing index to ensure a checkpoint belongs
        /// to the current ring (e.g. proving between 3 and 5 will leave indexes 4 and 5 untouched)
        uint256 index;
        /// @dev May be anything that describes the rollup state at a given data feed publication (e.g. a state root)
        bytes32 value;
    }

    struct CheckpointBuffer {
        /// @dev Represents the latest overall index (i.e. the index if the buffer didn't wrap around)
        uint256 _lastIndex;
        Checkpoint[] _checkpoints;
    }

    /// Intialization

    function setup(CheckpointBuffer storage self, uint256 size) internal {
        clear(self);
        Checkpoint[] storage _checkpoints = self._checkpoints;
        assembly ("memory-safe") {
            sstore(_checkpoints.slot, size)
        }
    }

    /// Getters

    function clear(CheckpointBuffer storage self) internal {
        self._lastIndex = 0;
    }

    function length(CheckpointBuffer storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    function last(CheckpointBuffer storage self) internal view returns (Checkpoint storage checkpoint) {
        return at(self, lastIndex(self));
    }

    function lastIndex(CheckpointBuffer storage self) internal view returns (uint256) {
        return self._lastIndex;
    }

    function at(CheckpointBuffer storage self, uint256 index) internal view returns (Checkpoint storage checkpoint) {
        Checkpoint[] storage _checkpoints = self._checkpoints;
        uint256 pos = index % length(self);
        assembly ("memory-safe") {
            mstore(0x00, _checkpoints.slot)
            checkpoint.slot := add(keccak256(0x00, 0x20), pos)
        }
    }

    /// Setters

    function setAt(CheckpointBuffer storage self, uint256 index, bytes32 value)
        internal
        returns (CheckpointBuffer storage)
    {
        Checkpoint storage checkpoint = at(self, index);
        checkpoint.value = value;
        checkpoint.index = index;
        return self;
    }

    function setLastIndex(CheckpointBuffer storage self, uint256 index)
        internal
        returns (CheckpointBuffer storage)
    {
        self._lastIndex = index;
        return self;
    }
}
