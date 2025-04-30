// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library LibPercentage {
    using SafeCast for uint256;

    // COMMON PRECISION AMOUNTS (https://muens.io/solidity-percentages)
    uint256 constant BASIS_POINTS = 10000;
    uint256 constant TWO_DECIMALS = 100;

    /// @dev Calculates the percentage of a given value scaling by `precision` to limit rounding loss
    /// @param value The number to scale
    /// @param percentage The percentage expressed in `precision` units.
    /// @param precision The precision of `percentage` (e.g. percentage 5000 with BASIS_POINTS precision is 50%).
    /// @return _ The scaled value
    function scaleBy(uint256 value, uint16 percentage, uint256 precision) internal pure returns (uint96) {
        return (value * percentage / precision).toUint96();
    }

    /// @dev Calculates the percentage (represented in basis points) of a given value
    /// @param value The number to scale
    /// @param percentage The percentage expressed in basis points
    /// @return _ The scaled value
    function scaleBy(uint256 value, uint16 percentage) internal pure returns (uint96) {
        return scaleBy(value, percentage, BASIS_POINTS);
    }
}
