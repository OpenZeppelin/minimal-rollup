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
        // Allows depositer to specify a relayer address if they want
        // in order to avoid race conditions (zero address to allow any relayer)
        address relayer;
        // Address that is allowed to cancel the deposit on the destination chain (zero address means deposit is
        // uncancellable)
        address canceler;
    }

    /// @dev Emitted when a deposit is made.
    /// @param id The deposit id
    /// @param deposit The ETH deposit
    event DepositMade(bytes32 indexed id, ETHDeposit deposit);

    /// @dev Emitted when a deposit is claimed.
    /// @param id The deposit id
    /// @param deposit The claimed ETH deposit
    event DepositClaimed(bytes32 indexed id, ETHDeposit deposit);

    /// @dev Emitted when a deposit is cancelled.
    /// @param id The deposit id
    /// @param claimee The address that received the cancelled deposit
    event DepositCancelled(bytes32 indexed id, address claimee);

    /// @dev Failed to call the receiver with value.
    error FailedClaim();

    /// @dev Deposit has already been claimed or cancelled.
    error DepositAlreadyProcessed();

    /// @dev Only canceler can cancel a deposit.
    error OnlyCanceler();

    /// @notice Whether the deposit identified by `id` has been processed (claimed or cancelled).
    /// @param id The deposit id
    function processed(bytes32 id) external view returns (bool);

    /// @dev ETH Deposit identifier.
    /// @param ethDeposit The ETH deposit struct
    function getDepositId(ETHDeposit memory ethDeposit) external view returns (bytes32 id);

    /// @dev Creates an ETH deposit with `msg.value`
    /// @param to The receiver of the deposit
    /// @param data Any calldata to be sent to the receiver in case of a contract
    /// @param relayer Address of the allowed relayer (0 for any)
    /// @param canceler Address that is allowed to cancel the deposit (zero address means deposit is uncancellable)
    function deposit(address to, bytes memory data, address relayer, address canceler)
        external
        payable
        returns (bytes32 id);

    /// @dev Claims an ETH deposit created by the sender (`from`) with `nonce`. The `value` ETH claimed  is
    /// sent to the receiver (`to`) after verifying a storage proof.
    /// @param ethDeposit The ETH deposit struct
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or publicationId)
    /// @param proof Encoded proof of the storage slot where the deposit is stored
    function claimDeposit(ETHDeposit memory ethDeposit, uint256 height, bytes memory proof) external;

    /// @dev Initiates a cancel on the deposit, must be called by the canceler on the destination chain.
    /// @param ethDeposit The ETH deposit struct
    /// @param claimee The address that will receive the cancelled deposit
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or publicationId)
    /// @param proof Encoded proof of the storage slot where the deposit is stored
    function cancelDeposit(ETHDeposit memory ethDeposit, address claimee, uint256 height, bytes memory proof)
        external;
}
