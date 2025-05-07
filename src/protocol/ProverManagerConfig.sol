// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

abstract contract ProverManagerConfig {
    /// @dev Returns the maximum percentage (in bps) of the previous bid a prover can offer and still have a successful
    /// bid
    /// @return _ The maximum bid percentage value
    function _maxBidPercentage() internal view virtual returns (uint16);

    /// @dev Returns the time window after which a publication is considered old enough for prover eviction
    /// @return _ The liveness window value in seconds
    function _livenessWindow() internal view virtual returns (uint40);

    /// @dev Returns the time delay before a new prover takes over after a successful bid
    /// @return _ The succession delay value in seconds
    function _successionDelay() internal view virtual returns (uint40);

    /// @dev Returns the delay after which the current prover can exit, or is removed if evicted
    /// @return _ The exit delay value in seconds
    function _exitDelay() internal view virtual returns (uint40);

    /// @dev Returns the time window for a prover to submit a valid proof after their period ends
    /// @return _ The proving window value in seconds
    function _provingWindow() internal view virtual returns (uint40);

    /// @dev Returns the minimum stake required to be a prover
    /// @return _ The liveness bond value in wei
    function _livenessBond() internal view virtual returns (uint96);

    /// @dev Returns the percentage (in bps) of the liveness bond that the evictor gets as an incentive
    /// @return _ The evictor incentive percentage
    function _evictorIncentivePercentage() internal view virtual returns (uint16);

    /// @dev Returns the percentage (in bps) of the remaining liveness bond rewarded to the prover
    /// @return _ The reward percentage
    function _rewardPercentage() internal view virtual returns (uint16);

    /// @dev The percentage of the fee that is charged for delayed publications
    /// @dev It is recommended to set this to >100 since delayed publications should usually be charged at a higher rate
    /// @return _ The multiplier as a percentage (two decimals). This value should usually be greater than 100 (100%).
    function _delayedFeePercentage() internal view virtual returns (uint16);
}
