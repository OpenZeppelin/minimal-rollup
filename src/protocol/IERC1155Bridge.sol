// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Bridges ERC1155 tokens by creating and verifying ERC1155Deposits.
///
/// These can be created by calling the deposit function. Later, the receiver can
/// claim the deposit on the destination chain by using a storage proof.
interface IERC1155Bridge {
    struct ERC1155Deposit {
        // The nonce of the deposit
        uint256 nonce;
        // The sender of the deposit
        address from;
        // The receiver of the deposit
        address to;
        // The ERC1155 token address
        address token;
        // The token ID
        uint256 tokenId;
        // The amount of the deposit
        uint256 amount;
        // Any calldata to be sent to the receiver in case of a contract
        bytes data;
        // Application-specific context data (e.g., for relayer selection, tips, etc.)
        bytes context;
        // Address that is allowed to cancel the deposit on the destination chain (zero address means deposit is
        // uncancellable)
        address canceler;
    }

    /// @dev Emitted when a deposit is made.
    /// @param id The deposit id
    /// @param deposit The ERC1155 deposit
    event DepositMade(bytes32 indexed id, ERC1155Deposit deposit);

    /// @dev Emitted when a deposit is claimed.
    /// @param id The deposit id
    /// @param deposit The claimed ERC1155 deposit
    event DepositClaimed(bytes32 indexed id, ERC1155Deposit deposit);

    /// @dev Emitted when a deposit is cancelled.
    /// @param id The deposit id
    /// @param claimee The address that received the cancelled deposit
    event DepositCancelled(bytes32 indexed id, address claimee);

    /// @dev Failed to claim the deposit.
    error FailedClaim();

    /// @dev A deposit was already claimed.
    error AlreadyClaimed();

    /// @dev Only canceler can cancel a deposit.
    error OnlyCanceler();

    /// @dev Whether the deposit identified by `id` has been claimed or cancelled.
    /// @param id The deposit id
    function processed(bytes32 id) external view returns (bool);

    /// @dev ERC1155 Deposit identifier.
    /// @param erc1155Deposit The ERC1155 deposit struct
    function getDepositId(ERC1155Deposit memory erc1155Deposit) external view returns (bytes32 id);

    /// @dev Creates an ERC1155 deposit
    /// @param to The receiver of the deposit
    /// @param token The ERC1155 token address
    /// @param tokenId The token ID
    /// @param amount The amount to deposit
    /// @param data Any calldata to be sent to the receiver in case of a contract
    /// @param context Application-specific context data
    /// @param canceler Address on the destination chain that is allowed to cancel the deposit (zero address means
    /// deposit is uncancellable)
    function deposit(
        address to,
        address token,
        uint256 tokenId,
        uint256 amount,
        bytes memory data,
        bytes memory context,
        address canceler
    ) external returns (bytes32 id);

    /// @dev Claims an ERC1155 deposit created by the sender (`from`) with `nonce`. The deposited tokens are
    /// sent to the receiver (`to`) after verifying a storage proof.
    /// @param erc1155Deposit The ERC1155 deposit struct
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or publicationId)
    /// @param proof Encoded proof of the storage slot where the deposit is stored
    function claimDeposit(ERC1155Deposit memory erc1155Deposit, uint256 height, bytes memory proof) external;

    /// @dev Initiates a cancel on the deposit, must be called by the canceler on the destination chain.
    /// @param erc1155Deposit The ERC1155 deposit struct
    /// @param claimee The address that will receive the cancelled deposit
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or publicationId)
    /// @param proof Encoded proof of the storage slot where the deposit is stored
    function cancelDeposit(ERC1155Deposit memory erc1155Deposit, address claimee, uint256 height, bytes memory proof)
        external;
}
