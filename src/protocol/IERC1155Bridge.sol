// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Bridges ERC1155 tokens by creating and verifying ERC1155Deposits.
///
/// These can be created by calling the deposit function. Later, the receiver can
/// claim the deposit on the destination chain by using a storage proof.
interface IERC1155Bridge {
    struct TokenDescription {
        // The original token address on the source chain
        address originalToken;
        // The base URI for the token collection
        string uri;
    }

    struct ERC1155Deposit {
        // The nonce of the deposit
        uint256 nonce;
        // The sender of the deposit
        address from;
        // The receiver of the deposit
        address to;
        // The original ERC1155 token address (always refers to the original token, not bridged)
        address originalToken;
        // The token ID
        uint256 tokenId;
        // The amount of the deposit
        uint256 amount;
        // The token URI (metadata) for this specific token
        string tokenURI;
        // Address that is allowed to cancel the deposit on the destination chain (zero address means deposit is
        // uncancellable)
        address canceler;
    }

    /// @dev Emitted when a token description is recorded on the source chain.
    /// @param id The token description id
    /// @param description The token description data
    event TokenDescriptionRecorded(bytes32 indexed id, TokenDescription description);

    /// @dev Emitted when a counterpart token is deployed on the destination chain.
    /// @param id The token description id
    /// @param description The token description data
    /// @param deployedToken The address of the deployed counterpart token
    event CounterpartTokenDeployed(bytes32 indexed id, TokenDescription description, address indexed deployedToken);

    /// @dev Emitted when a deposit is made.
    /// @param id The deposit id
    /// @param deposit The ERC1155 deposit
    event DepositMade(bytes32 indexed id, ERC1155Deposit deposit, address localToken);

    /// @dev Emitted when a deposit is claimed.
    /// @param id The deposit id
    /// @param deposit The claimed ERC1155 deposit
    event DepositClaimed(bytes32 indexed id, ERC1155Deposit deposit);

    /// @dev Emitted when a deposit is cancelled.
    /// @param id The deposit id
    /// @param claimee The address that received the cancelled deposit
    event DepositCancelled(bytes32 indexed id, address claimee);

    /// @dev A deposit was already claimed.
    error AlreadyClaimed();

    /// @dev Only canceler can cancel a deposit.
    error OnlyCanceler();

    /// @dev Counterpart token has already been deployed.
    error CounterpartTokenAlreadyDeployed();

    /// @dev Whether the action identified by `id` has been processed on this chain. If `id` is a deposit, this means
    /// the deposit was claimed or cancelled. If `id` is a token description, this means the counterpart token was
    /// deployed.
    /// @param id The deposit or token description id
    function processed(bytes32 id) external view returns (bool);

    /// @dev Get the deployed counterpart token address (on the destination chain) for an original token.
    /// @param originalToken The original token address on the source chain
    function getCounterpartToken(address originalToken) external view returns (address);

    /// @dev Token description identifier.
    /// @param tokenDesc The token description struct
    function getTokenDescriptionId(TokenDescription memory tokenDesc) external pure returns (bytes32 id);

    /// @dev ERC1155 Deposit identifier.
    /// @param erc1155Deposit The ERC1155 deposit struct
    function getDepositId(ERC1155Deposit memory erc1155Deposit) external pure returns (bytes32 id);

    /// @dev Records a token description for bridging by reading its metadata and sending a signal.
    /// @param token The ERC1155 token address to record description for
    function recordTokenDescription(address token) external returns (bytes32 id);

    /// @dev Proves a token description from the source chain and deploys the counterpart token.
    /// @param tokenDesc The token description data
    /// @param height The height of the checkpoint on the source chain
    /// @param proof Encoded proof of the token description signal
    function deployCounterpartToken(TokenDescription memory tokenDesc, uint256 height, bytes memory proof)
        external
        returns (address deployedToken);

    /// @dev Creates an ERC1155 deposit
    /// @param to The receiver of the deposit
    /// @param localToken The ERC1155 token address
    /// @param tokenId The token ID
    /// @param amount The amount to deposit
    /// @param canceler Address on the destination chain that is allowed to cancel the deposit (zero address means
    /// deposit is uncancellable)
    function deposit(address to, address localToken, uint256 tokenId, uint256 amount, address canceler)
        external
        returns (bytes32 id);

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
