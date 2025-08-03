// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @dev Bridges ERC20 tokens by creating and verifying ERC20Deposits.
///
/// These can be created by calling the deposit function. Later, the receiver can
/// claim the deposit on the destination chain by using a storage proof.
interface IERC20Bridge {
    struct TokenDescription {
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
        address originalToken;
        // The amount of the deposit
        uint256 amount;
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
    /// @param deposit The ERC20 deposit
    event DepositMade(bytes32 indexed id, ERC20Deposit deposit, address localToken);

    /// @dev Emitted when a deposit is claimed.
    /// @param id The deposit id
    /// @param deposit The claimed ERC20 deposit
    event DepositClaimed(bytes32 indexed id, ERC20Deposit deposit);

    /// @dev A deposit was already claimed.
    error AlreadyClaimed();

    /// @dev Counterpart token has already been deployed.
    error CounterpartTokenAlreadyDeployed();

    /// @dev Whether the action identified by `id` has been processed on this chain. If `id` is a deposit, this means
    /// the deposit was claimed. If `id` is a token description, this means the counterpart token was deployed.
    /// @param id The deposit or token description id
    function processed(bytes32 id) external view returns (bool);

    /// @dev Get the deployed token address for an original token (on destination chain).
    /// @param originalToken The original token address
    function getDeployedToken(address originalToken) external view returns (address);

    /// @dev Token description identifier.
    /// @param tokenDesc The token description struct
    function getTokenDescriptionId(TokenDescription memory tokenDesc) external pure returns (bytes32 id);

    /// @dev ERC20 Deposit identifier.
    /// @param erc20Deposit The ERC20 deposit struct
    function getDepositId(ERC20Deposit memory erc20Deposit) external pure returns (bytes32 id);

    /// @dev Records a token description for bridging by reading its metadata and sending a signal.
    /// @param token The ERC20 token address to record description for
    function recordTokenDescription(address token) external returns (bytes32 id);

    /// @dev Proves a token description from the source chain and deploys the counterpart token.
    /// @param tokenDesc The token description data
    /// @param height The height of the checkpoint on the source chain
    /// @param proof Encoded proof of the token description signal
    function deployCounterpartToken(TokenDescription memory tokenDesc, uint256 height, bytes memory proof)
        external
        returns (address deployedToken);

    /// @dev Creates an ERC20 deposit
    /// @param to The receiver of the deposit
    /// @param originalToken The ERC20 token address
    /// @param amount The amount to deposit
    function deposit(address to, address originalToken, uint256 amount) external returns (bytes32 id);

    /// @dev Claims an ERC20 deposit created by the sender (`from`) with `nonce`. The deposited tokens are
    /// sent to the receiver (`to`) after verifying a storage proof.
    /// @param erc20Deposit The ERC20 deposit struct
    /// @param height The `height` of the checkpoint on the source chain (i.e. the block number or publicationId)
    /// @param proof Encoded proof of the storage slot where the deposit is stored
    function claimDeposit(ERC20Deposit memory erc20Deposit, uint256 height, bytes memory proof) external;
}
