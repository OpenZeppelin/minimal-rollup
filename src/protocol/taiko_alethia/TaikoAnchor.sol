// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ICommitmentStore} from "../ICommitmentStore.sol";

///@dev This contains all the fields of the Ethereum block header in the cancun fork taken from
/// https://github.com/ethereum/go-ethereum/blob/master/core/types/block.go#L75
struct BlockHeader {
    bytes32 parentHash;
    bytes32 omnersHash;
    address coinbase;
    bytes32 stateRoot;
    bytes32 transactionsRoot;
    bytes32 receiptsRoot;
    bytes logsBloom;
    uint256 difficulty;
    uint256 number;
    uint64 gasLimit;
    uint64 gasUsed;
    uint64 timestamp;
    bytes extraData;
    bytes32 mixedHash;
    uint64 nonce;
    uint256 baseFeePerGas;
    bytes32 withdrawalsRoot;
    uint64 blobGasUsed;
    uint64 excessBlobGas;
    bytes32 parentBeaconBlockRoot;
    bytes32 requestsHash;
}

contract TaikoAnchor {
    event Anchor(uint256 publicationId, uint256 anchorBlockId, bytes32 anchorBlockHash, uint32 parentGasUsed);

    /// @dev The header provided does not match the block hash
    /// @param headerHash The header hash
    error HeaderMismatch(bytes32 headerHash);

    /// @dev The sender is not the permitted golden touch address
    error UnauthorizedSender();

    /// @dev The fixed base fee must be greater than 0
    error InvalidFixedBaseFee();

    /// @dev The publication ID is too small
    /// @param providedId The provided publication ID
    /// @param requiredId The minimum required publication ID
    error PublicationIdTooSmall(uint256 providedId, uint256 requiredId);

    /// @dev The anchor block ID is too small
    /// @param providedId The provided anchor block ID
    /// @param requiredId The minimum required anchor block ID
    error AnchorBlockIdTooSmall(uint256 providedId, uint256 requiredId);

    /// @dev The anchor block hash is zero
    error ZeroAnchorBlockHash();

    /// @dev The circular hash does not match the expected value
    /// @param expected The expected circular hash
    /// @param actual The actual circular hash
    error CircularHashMismatch(bytes32 expected, bytes32 actual);

    /// @dev The base fee does not match the fixed base fee
    /// @param expected The expected fixed base fee
    /// @param actual The actual base fee
    error BaseFeeMismatch(uint256 expected, uint256 actual);

    uint256 public immutable fixedBaseFee;
    address public immutable permittedSender; // 0x0000777735367b36bC9B61C50022d9D0700dB4Ec

    ICommitmentStore public immutable commitmentStore;

    uint256 public lastAnchorBlockId;
    uint256 public lastPublicationId;
    bytes32 public circularBlocksHash;
    mapping(uint256 blockId => bytes32 blockHash) public blockHashes;

    modifier onlyFromPermittedSender() {
        require(msg.sender == permittedSender, UnauthorizedSender());
        _;
    }

    /// @dev This constructor is only used in tests as the contract will be pre-deployed in the L2 genesis
    /// @param _fixedBaseFee The fixed base fee for the rollup
    /// @param _permittedSender The address of the sender that can call the anchor function
    /// @param _commitmentStore contract responsible storing historical commitments
    constructor(uint256 _fixedBaseFee, address _permittedSender, address _commitmentStore) {
        require(_fixedBaseFee > 0, InvalidFixedBaseFee());
        fixedBaseFee = _fixedBaseFee;
        permittedSender = _permittedSender;

        uint256 parentId = block.number - 1;
        blockHashes[parentId] = blockhash(parentId);
        (circularBlocksHash,) = _calcCircularBlocksHash(block.number);
        commitmentStore = ICommitmentStore(_commitmentStore);
    }

    /// @dev The node software will guarantee and the prover will verify the following:
    /// 1. This function is transacted as the first transaction in the first L2 block derived from the same publication;
    /// 2. This function's gas limit is a fixed value;
    /// 3. This function will not revert;
    /// 4. The parameters correspond to the real L1 state, except _anchorBlockHeader is validated in this function
    /// rather than the node
    /// @dev The anchor block header is provided in order to extract the L1 state root needed for storage verification
    /// logic (i.e. verifying an L1 signal)
    /// @param _publicationId The publication that contains this anchor transaction (as the first transaction)
    /// @param _anchorBlockId The latest L1 block known to the L2 blocks in this publication
    /// @param _anchorBlockHash The block hash of the L1 anchor block
    /// @param _anchorBlockHeader The block header of the L1 anchor block
    /// @param _parentGasUsed The gas used in the parent block
    function anchor(
        uint256 _publicationId,
        uint256 _anchorBlockId,
        bytes32 _anchorBlockHash,
        BlockHeader calldata _anchorBlockHeader,
        uint32 _parentGasUsed
    ) external onlyFromPermittedSender {
        // Make sure this function can only succeed once per publication
        require(_publicationId > lastPublicationId, PublicationIdTooSmall(_publicationId, lastPublicationId + 1));
        lastPublicationId = _publicationId;

        // Make sure L1->L2 sync will use newer block hash
        require(_anchorBlockId >= lastAnchorBlockId, AnchorBlockIdTooSmall(_anchorBlockId, lastAnchorBlockId));
        require(_anchorBlockHash != 0, ZeroAnchorBlockHash());

        // Persist anchor block hashes
        if (_anchorBlockId > lastAnchorBlockId) {
            lastAnchorBlockId = _anchorBlockId;
            bytes32 headerHash = keccak256(abi.encode(_anchorBlockHeader));
            require(headerHash == _anchorBlockHash, HeaderMismatch(headerHash));
            bytes32 commitment = keccak256(abi.encode(_anchorBlockHeader.stateRoot, _anchorBlockHash));
            // Stores the state of the other chain
            commitmentStore.storeCommitment(_anchorBlockId, commitment);
        }

        // Store the parent block hash in the _blockhashes mapping
        uint256 parentId = block.number - 1;
        blockHashes[parentId] = blockhash(parentId);

        // Calculate the current and new circular hash for the last 255 blocksbased on the parent block ID
        (bytes32 currentHash, bytes32 newHash) = _calcCircularBlocksHash(parentId);
        require(circularBlocksHash == currentHash, CircularHashMismatch(circularBlocksHash, currentHash));
        circularBlocksHash = newHash;

        _verifyBaseFee(_parentGasUsed);

        emit Anchor(_publicationId, _anchorBlockId, _anchorBlockHash, _parentGasUsed);
    }

    function l1BlockHashes(uint256 blockId) external view returns (bytes32 blockHash) {
        return commitmentStore.commitmentAt(address(this), blockId);
    }

    /// @dev Calculates the aggregated ancestor block hash for the given block ID
    /// It uses a ring buffer of 255 bytes32 to store the previous 255 block hashes and the current chain ID
    /// @param _blockId The ID of the block for which the public input hash is calculated
    /// @return currentHash_ The public input hash for the previous state
    /// @return newHash_ The public input hash for the new state
    function _calcCircularBlocksHash(uint256 _blockId) private view returns (bytes32 currentHash_, bytes32 newHash_) {
        // a ring buffer of 255 bytes32 and one extra bytes32 for the chain ID
        bytes32[256] memory inputs;
        inputs[255] = bytes32(block.chainid); // not part of the ring buffer

        unchecked {
            // Put the previous 255 blockhashes (excluding the parent's) into a ring buffer
            for (uint256 i; i < 255 && _blockId > i; ++i) {
                uint256 j = _blockId - i - 1;
                inputs[j % 255] = blockhash(j);
            }
        }

        assembly {
            currentHash_ := keccak256(inputs, mul(256, 32))
        }

        inputs[_blockId % 255] = blockhash(_blockId);
        assembly {
            newHash_ := keccak256(inputs, mul(256, 32))
        }
    }

    // For now, we simply use a constant base fee
    function _verifyBaseFee(uint32 /*_parentGasUsed*/ ) internal view {
        require(block.basefee == fixedBaseFee, BaseFeeMismatch(fixedBaseFee, block.basefee));
    }
}
