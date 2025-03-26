// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Bridges native value (i.e. ETH) by creating and verifying ETHDeposits.
///
/// These can be created by sending value to the `depositETH` function. Later, the receiver can
/// claim the deposit on the destination chain by using a storage proof.
interface IETHBridge {
    struct ETHDeposit {
        // The destination chain id
        uint64 chainId;
        // The nonce of the sender
        uint64 nonce;
        // The sender of the deposit
        address from;
        // The receiver of the deposit
        address to;
        // The amount of the deposit
        uint256 amount;
        // Any calldata to be sent to the receiver in case of a contract
        uint256 data;
    }

    /// @dev Emitted when a deposit is made.
    /// @param id The deposit id
    /// @param deposit The ETH deposit
    event ETHDepositMade(bytes32 indexed id, ETHDeposit deposit);

    /// @dev Emitted when a deposit is claimed.
    /// @param id The deposit id
    /// @param deposit The claimed ETH deposit
    event ETHDepositClaimed(bytes32 indexed id, ETHDeposit deposit);

    /// @dev Failed to call the receiver with value.
    error FailedClaim();

    /// @dev A deposit was already claimed.
    error AlreadyClaimed();

    /// @dev Whether the deposit identified by `id` has been claimed.
    /// @param id The deposit id
    function claimed(bytes32 id) external view returns (bool);

    /// @dev ETH Deposit identifier.
    /// @param deposit The ETH deposit
    function getDepositId(ETHDeposit memory deposit) external view returns (bytes32 id);

    /// @dev Creates an ETH deposit with `msg.value` for the receiver (`to`) to be claimed on the `chainId`.
    /// @param chainId The destination chain id
    /// @param to The receiver of the deposit
    /// @param data Any calldata to be sent to the receiver in case of a contract
    function depositETH(uint64 chainId, address to, uint256 data) external payable returns (bytes32 id);

    /// @dev Claims an ETH depoist created on `chainId` by the sender (`from`) with `nonce`. The `value` ETH claimed  is
    /// sent to the receiver (`to`) after verifying a storage proof.
    /// @param deposit The ETH deposit
    /// @param root The state root
    /// @param accountProof Merkle proof for account state against global stateRoot
    /// @param stateProof Merkle proof for slot value against account's storageRoot
    function claimDeposit(
        ETHDeposit memory deposit,
        bytes32 root,
        bytes[] memory accountProof,
        bytes[] memory stateProof
    ) external returns (bytes32 id);
}
