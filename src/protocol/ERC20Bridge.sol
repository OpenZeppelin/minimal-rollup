// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BridgedERC20} from "./BridgedERC20.sol";
import {IERC20Bridge} from "./IERC20Bridge.sol";
import {ISignalService} from "./ISignalService.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

/// @title ERC20Bridge
/// @notice A decentralized bridge for ERC20 tokens that allows anyone to initialize tokens
/// @dev Uses a permissionless token initialization flow
contract ERC20Bridge is IERC20Bridge, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;

    mapping(bytes32 id => bool processed) private _processed;
    mapping(bytes32 id => bool provenInitializations) private _provenInitializations;
    mapping(address token => bool initialized) private _initializedTokens;
    mapping(bytes32 key => address deployedToken) private _deployedTokens;

    /// Incremental nonce to generate unique deposit IDs.
    uint256 private _globalDepositNonce;

    /// Incremental nonce to generate unique initialization IDs.
    uint256 private _globalInitializationNonce;

    ISignalService public immutable signalService;

    /// @dev Trusted source of commitments in the `CommitmentStore` that the bridge will use to validate withdrawals
    /// @dev This is the Anchor on L2 and the Checkpoint Tracker on the L1
    address public immutable trustedCommitmentPublisher;

    /// @dev The counterpart bridge contract on the other chain.
    /// This is used to locate deposit signals inside the other chain's state root.
    /// WARN: This address has no significance (and may be untrustworthy) on this chain.
    address public immutable counterpart;

    /// @dev The chain identifier for this chain
    uint256 public immutable chainId;

    constructor(address _signalService, address _trustedCommitmentPublisher, address _counterpart) {
        require(_signalService != address(0), "Empty signal service");
        require(_trustedCommitmentPublisher != address(0), "Empty trusted publisher");
        require(_counterpart != address(0), "Empty counterpart");

        signalService = ISignalService(_signalService);
        trustedCommitmentPublisher = _trustedCommitmentPublisher;
        counterpart = _counterpart;
        chainId = block.chainid;
    }

    /// @inheritdoc IERC20Bridge
    function processed(bytes32 id) public view returns (bool) {
        return _processed[id];
    }

    /// @inheritdoc IERC20Bridge
    function isTokenInitialized(address token) public view returns (bool) {
        return _initializedTokens[token];
    }

    /// @inheritdoc IERC20Bridge
    function isInitializationProven(bytes32 id) public view returns (bool) {
        return _provenInitializations[id];
    }

    /// @inheritdoc IERC20Bridge
    function getDeployedToken(address originalToken, uint256 sourceChain) public view returns (address) {
        bytes32 key = keccak256(abi.encode(originalToken, sourceChain));
        return _deployedTokens[key];
    }

    /// @inheritdoc IERC20Bridge
    function getInitializationId(TokenInitialization memory tokenInit) public pure returns (bytes32 id) {
        return _generateInitializationId(tokenInit);
    }

    /// @inheritdoc IERC20Bridge
    function getDepositId(ERC20Deposit memory erc20Deposit) public pure returns (bytes32 id) {
        return _generateDepositId(erc20Deposit);
    }

    /// @inheritdoc IERC20Bridge
    function initializeToken(address token) external returns (bytes32 id) {
        require(token != address(0), "Invalid token address");
        require(!_initializedTokens[token], "Token already initialized");

        // Read token metadata
        string memory name = IERC20Metadata(token).name();
        string memory symbol = IERC20Metadata(token).symbol();
        uint8 decimals = IERC20Metadata(token).decimals();

        TokenInitialization memory tokenInit = TokenInitialization({
            nonce: _globalInitializationNonce,
            originalToken: token,
            name: name,
            symbol: symbol,
            decimals: decimals,
            sourceChain: chainId
        });

        id = _generateInitializationId(tokenInit);
        unchecked {
            ++_globalInitializationNonce;
        }

        // Mark token as initialized locally
        _initializedTokens[token] = true;

        // Send signal for cross-chain initialization
        signalService.sendSignal(id);

        emit TokenInitialized(id, tokenInit);
    }

    /// @inheritdoc IERC20Bridge
    function proveTokenInitialization(TokenInitialization memory tokenInit, uint256 height, bytes memory proof)
        external
        returns (address deployedToken)
    {
        bytes32 id = _generateInitializationId(tokenInit);
        require(!_provenInitializations[id], InitializationAlreadyProven());

        // Verify the initialization signal from the source chain
        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        // Mark initialization as proven
        _provenInitializations[id] = true;

        // Deploy the bridged token
        deployedToken = address(
            new BridgedERC20(
                tokenInit.name,
                tokenInit.symbol,
                tokenInit.decimals,
                address(this),
                tokenInit.originalToken,
                tokenInit.sourceChain
            )
        );

        // Store the mapping
        bytes32 key = keccak256(abi.encode(tokenInit.originalToken, tokenInit.sourceChain));
        _deployedTokens[key] = deployedToken;

        emit TokenInitializationProven(id, tokenInit, deployedToken);
    }

    /// @inheritdoc IERC20Bridge
    function deposit(address to, address localToken, uint256 amount, address canceler)
        external
        nonReentrant
        returns (bytes32 id)
    {
        // Check if token is initialized (for original tokens) or is a bridged token deployed by this bridge
        require(_initializedTokens[localToken] || _isBridgedToken(localToken), TokenNotInitialized());

        ERC20Deposit memory erc20Deposit = ERC20Deposit({
            nonce: _globalDepositNonce,
            from: msg.sender,
            to: to,
            localToken: localToken,
            sourceChain: chainId,
            amount: amount,
            canceler: canceler
        });

        id = _generateDepositId(erc20Deposit);
        unchecked {
            ++_globalDepositNonce;
        }

        // Handle token transfer based on whether it's a bridged token or original token
        if (_isBridgedToken(localToken)) {
            // This is a bridged token being sent back to its origin, burn it
            IERC20(localToken).safeTransferFrom(msg.sender, address(this), amount);
            BridgedERC20(localToken).burn(address(this), amount);
        } else {
            // This is an original token, hold it
            IERC20(localToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        // Send signal
        signalService.sendSignal(id);
        emit DepositMade(id, erc20Deposit);
    }

    /// @inheritdoc IERC20Bridge
    function claimDeposit(ERC20Deposit memory erc20Deposit, uint256 height, bytes memory proof) external nonReentrant {
        bytes32 id = _claimDeposit(erc20Deposit, erc20Deposit.to, height, proof);
        emit DepositClaimed(id, erc20Deposit);
    }

    /// @inheritdoc IERC20Bridge
    function cancelDeposit(ERC20Deposit memory erc20Deposit, address claimee, uint256 height, bytes memory proof)
        external
        nonReentrant
    {
        require(msg.sender == erc20Deposit.canceler, OnlyCanceler());

        bytes32 id = _claimDeposit(erc20Deposit, claimee, height, proof);

        emit DepositCancelled(id, claimee);
    }

    function _claimDeposit(ERC20Deposit memory erc20Deposit, address to, uint256 height, bytes memory proof)
        internal
        returns (bytes32 id)
    {
        id = _generateDepositId(erc20Deposit);
        require(!processed(id), AlreadyClaimed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _processed[id] = true;
        _sendERC20(erc20Deposit, to);
    }

    /// @dev Function to transfer ERC20 to the receiver.
    /// @param erc20Deposit The deposit information containing the token and amount
    /// @param to Address to send the tokens to
    function _sendERC20(ERC20Deposit memory erc20Deposit, address to) internal {
        if (erc20Deposit.sourceChain != chainId) {
            // This is a deposit from another chain, check if we have the bridged token deployed
            bytes32 key = keccak256(abi.encode(erc20Deposit.localToken, erc20Deposit.sourceChain));
            address deployedToken = _deployedTokens[key];

            if (deployedToken != address(0)) {
                // Mint the bridged token
                BridgedERC20(deployedToken).mint(to, erc20Deposit.amount);
            } else {
                // This should not happen if token was properly initialized
                revert("Bridged token not found");
            }
        } else {
            // This is a deposit from the same chain (bridged token going back to origin)
            // Transfer the original token that we hold
            IERC20(erc20Deposit.localToken).safeTransfer(to, erc20Deposit.amount);
        }
    }

    /// @dev Checks if a token is a bridged token deployed by this bridge.
    /// @param token The token address to check
    /// @return true if the token is a bridged token deployed by this bridge
    function _isBridgedToken(address token) internal view returns (bool) {
        try BridgedERC20(token).bridge() returns (address bridge) {
            return bridge == address(this);
        } catch {
            return false;
        }
    }

    /// @dev Generates a unique ID for a token initialization.
    /// @param tokenInit Token initialization to generate an ID for
    function _generateInitializationId(TokenInitialization memory tokenInit) internal pure returns (bytes32) {
        return keccak256(abi.encode(tokenInit));
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param erc20Deposit Deposit to generate an ID for
    function _generateDepositId(ERC20Deposit memory erc20Deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(erc20Deposit));
    }
}
