// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Bridges native value (i.e. ETH) by creating and verifying ETHDeposits.
///
/// These can be created by sending value to the `deposit` function. Later, the receiver can
/// claim the deposit on the destination chain by using a storage proof.
interface IETHBridge {
    struct ETHDeposit {
        // The nonce of the deposit
        uint256 nonce;
        // The sender of the deposit
        address from;
        // The receiver of the deposit
        address to;
        // The amount of the deposit
        uint256 amount;
        // Any calldata to be sent to the receiver in case of a contract
        bytes data;
    }

    /// @dev Emitted when a deposit is made.
    /// @param id The deposit id
    /// @param deposit The ETH deposit
    event DepositMade(bytes32 indexed id, ETHDeposit deposit);

    /// @dev Emitted when a deposit is claimed.
    /// @param id The deposit id
    /// @param deposit The claimed ETH deposit
    event DepositClaimed(bytes32 indexed id, ETHDeposit deposit);

    /// @dev Failed to call the receiver with value.
    error FailedClaim();

    /// @dev A deposit was already claimed.
    error AlreadyClaimed();

    /// @dev Whether the deposit identified by `id` has been claimed.
    /// @param id The deposit id
    function claimed(bytes32 id) external view returns (bool);

    /// @dev ETH Deposit identifier.
    /// @param ethDeposit The ETH deposit struct
    function getDepositId(ETHDeposit memory ethDeposit) external view returns (bytes32 id);

    /// @dev Creates an ETH deposit with `msg.value`
    /// @param to The receiver of the deposit
    /// @param data Any calldata to be sent to the receiver in case of a contract
    function deposit(address to, bytes memory data) external payable returns (bytes32 id);

    /// @dev Claims an ETH deposit created on by the sender (`from`) with `nonce`. The `value` ETH claimed  is
    /// sent to the receiver (`to`) after verifying a storage proof.
    /// @param ethDeposit The ETH deposit struct ff
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or commitmentId)
    /// @param proof Encoded proof of the storage slot where the deposit is stored
    function claimDeposit(ETHDeposit memory ethDeposit, uint256 height, bytes memory proof) external;
}
