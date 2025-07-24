// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Bridges ERC20 tokens by creating and verifying ERC20Deposits.
///
/// These can be created by calling the deposit function. Later, the receiver can
/// claim the deposit on the destination chain by using a storage proof.
interface IERC20Bridge {
    struct TokenInitialization {
        // The original token address on the source chain
        address originalToken;
        // The token name
        string name;
        // The token symbol
        string symbol;
        // The token decimals
        uint8 decimals;
    }

    struct ERC20Deposit {
        // The nonce of the deposit
        uint256 nonce;
        // The sender of the deposit
        address from;
        // The receiver of the deposit
        address to;
        // The original ERC20 token address (always refers to the original token, not bridged)
        address localToken;
        // The amount of the deposit
        uint256 amount;
        // Address that is allowed to cancel the deposit on the destination chain (zero address means deposit is
        // uncancellable)
        address canceler;
    }

    /// @dev Emitted when a token is initialized on the source chain.
    /// @param id The initialization id
    /// @param initialization The token initialization data
    event TokenInitialized(bytes32 indexed id, TokenInitialization initialization);

    /// @dev Emitted when a token initialization is proven on the destination chain.
    /// @param id The initialization id
    /// @param initialization The token initialization data
    /// @param deployedToken The address of the deployed bridged token
    event TokenInitializationProven(
        bytes32 indexed id, TokenInitialization initialization, address indexed deployedToken
    );

    /// @dev Emitted when a deposit is made.
    /// @param id The deposit id
    /// @param deposit The ERC20 deposit
    event DepositMade(bytes32 indexed id, ERC20Deposit deposit);

    /// @dev Emitted when a deposit is claimed.
    /// @param id The deposit id
    /// @param deposit The claimed ERC20 deposit
    event DepositClaimed(bytes32 indexed id, ERC20Deposit deposit);

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

    /// @dev Token has not been initialized for bridging.
    error TokenNotInitialized();

    /// @dev Token initialization has already been proven.
    error InitializationAlreadyProven();

    /// @dev Whether the deposit identified by `id` has been claimed or cancelled.
    /// @param id The deposit id
    function processed(bytes32 id) external view returns (bool);

    /// @dev Whether a token has been initialized for bridging.
    /// @param token The token address
    function isTokenInitialized(address token) external view returns (bool);

    /// @dev Whether a token initialization has been proven (on destination chain).
    /// @param id The initialization id
    function isInitializationProven(bytes32 id) external view returns (bool);

    /// @dev Get the deployed token address for an original token (on destination chain).
    /// @param originalToken The original token address
    function getDeployedToken(address originalToken) external view returns (address);

    /// @dev Token initialization identifier.
    /// @param tokenInit The token initialization struct
    function getInitializationId(TokenInitialization memory tokenInit) external pure returns (bytes32 id);

    /// @dev ERC20 Deposit identifier.
    /// @param erc20Deposit The ERC20 deposit struct
    function getDepositId(ERC20Deposit memory erc20Deposit) external pure returns (bytes32 id);

    /// @dev Initializes a token for bridging by reading its metadata and sending a signal.
    /// @param token The ERC20 token address to initialize
    function initializeToken(address token) external returns (bytes32 id);

    /// @dev Proves a token initialization from the source chain and deploys the bridged token.
    /// @param tokenInit The token initialization data
    /// @param height The height of the checkpoint on the source chain
    /// @param proof Encoded proof of the initialization signal
    function proveTokenInitialization(
        TokenInitialization memory tokenInit,
        uint256 height,
        bytes memory proof
    ) external returns (address deployedToken);

    /// @dev Creates an ERC20 deposit
    /// @param to The receiver of the deposit
    /// @param localToken The ERC20 token address
    /// @param amount The amount to deposit
    /// @param canceler Address on the destination chain that is allowed to cancel the deposit (zero address means
    /// deposit is uncancellable)
    function deposit(address to, address localToken, uint256 amount, address canceler) external returns (bytes32 id);

    /// @dev Claims an ERC20 deposit created by the sender (`from`) with `nonce`. The deposited tokens are
    /// sent to the receiver (`to`) after verifying a storage proof.
    /// @param erc20Deposit The ERC20 deposit struct
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or publicationId)
    /// @param proof Encoded proof of the storage slot where the deposit is stored
    function claimDeposit(ERC20Deposit memory erc20Deposit, uint256 height, bytes memory proof) external;

    /// @dev Initiates a cancel on the deposit, must be called by the canceler on the destination chain.
    /// @param erc20Deposit The ERC20 deposit struct
    /// @param claimee The address that will receive the cancelled deposit
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or publicationId)
    /// @param proof Encoded proof of the storage slot where the deposit is stored
    function cancelDeposit(ERC20Deposit memory erc20Deposit, address claimee, uint256 height, bytes memory proof)
        external;
}
