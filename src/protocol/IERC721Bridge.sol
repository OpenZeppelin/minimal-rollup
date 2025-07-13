// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Bridges ERC721 tokens by creating and verifying ERC721Deposits.
///
/// These can be created by calling the deposit function. Later, the receiver can
/// claim the deposit on the destination chain by using a storage proof.
interface IERC721Bridge {
    struct ERC721Deposit {
        // The nonce of the deposit
        uint256 nonce;
        // The sender of the deposit
        address from;
        // The receiver of the deposit
        address to;
        // The ERC721 token address
        address token;
        // The token ID
        uint256 tokenId;
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
    /// @param deposit The ERC721 deposit
    event DepositMade(bytes32 indexed id, ERC721Deposit deposit);

    /// @dev Emitted when a deposit is claimed.
    /// @param id The deposit id
    /// @param deposit The claimed ERC721 deposit
    event DepositClaimed(bytes32 indexed id, ERC721Deposit deposit);

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

    /// @dev ERC721 Deposit identifier.
    /// @param erc721Deposit The ERC721 deposit struct
    function getDepositId(ERC721Deposit memory erc721Deposit) external view returns (bytes32 id);

    /// @dev Creates an ERC721 deposit
    /// @param to The receiver of the deposit
    /// @param token The ERC721 token address
    /// @param tokenId The token ID to deposit
    /// @param data Any calldata to be sent to the receiver in case of a contract
    /// @param context Application-specific context data
    /// @param canceler Address on the destination chain that is allowed to cancel the deposit (zero address means
    /// deposit is uncancellable)
    function deposit(address to, address token, uint256 tokenId, bytes memory data, bytes memory context, address canceler)
        external returns (bytes32 id);

    /// @dev Claims an ERC721 deposit created by the sender (`from`) with `nonce`. The deposited token is
    /// sent to the receiver (`to`) after verifying a storage proof.
    /// @param erc721Deposit The ERC721 deposit struct
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or publicationId)
    /// @param proof Encoded proof of the storage slot where the deposit is stored
    function claimDeposit(ERC721Deposit memory erc721Deposit, uint256 height, bytes memory proof) external;

    /// @dev Initiates a cancel on the deposit, must be called by the canceler on the destination chain.
    /// @param erc721Deposit The ERC721 deposit struct
    /// @param claimee The address that will receive the cancelled deposit
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or publicationId)
    /// @param proof Encoded proof of the storage slot where the deposit is stored
    function cancelDeposit(ERC721Deposit memory erc721Deposit, address claimee, uint256 height, bytes memory proof)
        external;
} 