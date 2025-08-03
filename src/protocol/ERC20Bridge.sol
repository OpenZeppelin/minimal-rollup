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
/// @notice A decentralized bridge for ERC20 tokens that allows anyone to bridge any ERC20 token
/// @dev Uses a permissionless flow to initialize the counterpart token on the destination chain.
contract ERC20Bridge is IERC20Bridge, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;

    /// @dev Signal type constants to differentiate signal categories
    bytes32 private constant TOKEN_DESCRIPTION_SIGNAL_PREFIX = keccak256("ERC20_TOKEN_DESCRIPTION");
    bytes32 private constant DEPOSIT_SIGNAL_PREFIX = keccak256("ERC20_DEPOSIT");

    mapping(bytes32 id => bool processed) private _processed;
    mapping(address originalToken => address counterpartToken) private _counterpartTokens;
    mapping(address token => bool isBridgedToken) private _isBridgedTokens;

    /// Incremental nonce to generate unique deposit IDs.
    uint256 private _globalDepositNonce;

    ISignalService public immutable signalService;

    /// @dev Trusted source of commitments in the `CommitmentStore` that the bridge will use to validate withdrawals
    /// @dev This is the Anchor on L2 and the Checkpoint Tracker on the L1
    address public immutable trustedCommitmentPublisher;

    /// @dev The counterpart bridge contract on the other chain.
    /// This is used to locate deposit signals inside the other chain's state root.
    /// WARN: This address has no significance (and may be untrustworthy) on this chain.
    address public immutable counterpart;

    constructor(address _signalService, address _trustedCommitmentPublisher, address _counterpart) {
        require(_signalService != address(0), "Empty signal service");
        require(_trustedCommitmentPublisher != address(0), "Empty trusted publisher");
        require(_counterpart != address(0), "Empty counterpart");

        signalService = ISignalService(_signalService);
        trustedCommitmentPublisher = _trustedCommitmentPublisher;
        counterpart = _counterpart;
    }

    /// @inheritdoc IERC20Bridge
    function processed(bytes32 id) public view returns (bool) {
        return _processed[id];
    }

    /// @inheritdoc IERC20Bridge
    function getCounterpartToken(address originalToken) public view returns (address) {
        return _counterpartTokens[originalToken];
    }

    /// @inheritdoc IERC20Bridge
    function getTokenDescriptionId(TokenDescription memory tokenDesc) public pure returns (bytes32 id) {
        return _generateTokenDescriptionId(tokenDesc);
    }

    /// @inheritdoc IERC20Bridge
    function getDepositId(ERC20Deposit memory erc20Deposit) public pure returns (bytes32 id) {
        return _generateDepositId(erc20Deposit);
    }

    /// @inheritdoc IERC20Bridge
    function recordTokenDescription(address token) external returns (bytes32 id) {
        require(token != address(0), "Invalid token address");

        string memory name;
        string memory symbol;
        uint8 decimals;

        try IERC20Metadata(token).name() returns (string memory _name) {
            name = _name;
        } catch {
            name = "Unknown Token Name";
        }

        try IERC20Metadata(token).symbol() returns (string memory _symbol) {
            symbol = _symbol;
        } catch {
            symbol = "UNKNOWN";
        }

        try IERC20Metadata(token).decimals() returns (uint8 _decimals) {
            decimals = _decimals;
        } catch {
            decimals = 18; // Standard default
        }

        TokenDescription memory tokenDesc =
            TokenDescription({originalToken: token, name: name, symbol: symbol, decimals: decimals});

        id = _generateTokenDescriptionId(tokenDesc);

        signalService.sendSignal(id);

        emit TokenDescriptionRecorded(id, tokenDesc);
    }

    /// @inheritdoc IERC20Bridge
    function deployCounterpartToken(TokenDescription memory tokenDesc, uint256 height, bytes memory proof)
        external
        returns (address deployedToken)
    {
        bytes32 id = _generateTokenDescriptionId(tokenDesc);
        require(!_processed[id], CounterpartTokenAlreadyDeployed());
        require(
            _counterpartTokens[tokenDesc.originalToken] == address(0),
            "Counterpart token already exists for this original token"
        );

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        deployedToken =
            address(new BridgedERC20(tokenDesc.name, tokenDesc.symbol, tokenDesc.decimals, tokenDesc.originalToken));
        _counterpartTokens[tokenDesc.originalToken] = deployedToken;
        _isBridgedTokens[deployedToken] = true;
        _processed[id] = true;

        emit CounterpartTokenDeployed(id, tokenDesc, deployedToken);
    }

    /// @inheritdoc IERC20Bridge
    function deposit(address to, address localToken, uint256 amount) external nonReentrant returns (bytes32 id) {
        bool isBridged = _isBridgedToken(localToken);
        address originalToken = isBridged ? BridgedERC20(localToken).originalToken() : localToken;

        ERC20Deposit memory erc20Deposit = ERC20Deposit({
            nonce: _globalDepositNonce,
            from: msg.sender,
            to: to,
            originalToken: originalToken,
            amount: amount
        });

        id = _generateDepositId(erc20Deposit);
        unchecked {
            ++_globalDepositNonce;
        }

        IERC20(localToken).safeTransferFrom(msg.sender, address(this), amount);
        if (isBridged) {
            BridgedERC20(localToken).burn(amount);
        }

        signalService.sendSignal(id);
        emit DepositMade(id, erc20Deposit, localToken);
    }

    /// @inheritdoc IERC20Bridge
    function claimDeposit(ERC20Deposit memory erc20Deposit, uint256 height, bytes memory proof) external nonReentrant {
        bytes32 id = _generateDepositId(erc20Deposit);
        require(!processed(id), AlreadyClaimed());

        signalService.verifySignal(height, trustedCommitmentPublisher, counterpart, id, proof);

        _processed[id] = true;
        _sendERC20(erc20Deposit);

        emit DepositClaimed(id, erc20Deposit);
    }

    /// @dev Function to transfer ERC20 to the receiver.
    /// @param erc20Deposit The deposit information containing the original token address
    function _sendERC20(ERC20Deposit memory erc20Deposit) internal {
        address deployedToken = _counterpartTokens[erc20Deposit.originalToken];

        if (deployedToken != address(0)) {
            BridgedERC20(deployedToken).mint(erc20Deposit.to, erc20Deposit.amount);
        } else {
            IERC20(erc20Deposit.originalToken).safeTransfer(erc20Deposit.to, erc20Deposit.amount);
        }
    }

    /// @dev Checks if a token is a bridged token deployed by this bridge.
    /// @param token The token address to check
    /// @return true if the token is a bridged token deployed by this bridge
    function _isBridgedToken(address token) internal view returns (bool) {
        return _isBridgedTokens[token];
    }

    /// @dev Generates a unique ID for a token description.
    /// @param tokenDesc Token description to generate an ID for
    function _generateTokenDescriptionId(TokenDescription memory tokenDesc) internal pure returns (bytes32) {
        return keccak256(abi.encode(TOKEN_DESCRIPTION_SIGNAL_PREFIX, tokenDesc));
    }

    /// @dev Generates a unique ID for a deposit.
    /// @param erc20Deposit Deposit to generate an ID for
    function _generateDepositId(ERC20Deposit memory erc20Deposit) internal pure returns (bytes32) {
        return keccak256(abi.encode(DEPOSIT_SIGNAL_PREFIX, erc20Deposit));
    }
}
