// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TaikoAnchor {
    event Anchor(uint256 publicationId, uint256 anchorBlockId, bytes32 anchorBlockHash, bytes32 parentGasUsed);

    uint256 public immutable fixedBaseFee;
    address public immutable permittedSender; // 0x0000777735367b36bC9B61C50022d9D0700dB4Ec

    uint256 public lastAnchorBlockId;
    uint256 public lastPublicationId;
    bytes32 public circularBlocksHash;
    mapping(uint256 blockId => bytes32 blockHash) public blockHashes;
    mapping(uint256 blockId => bytes32 blockHash) public l1BlockHashes;

    modifier onlyFromPermittedSender() {
        require(msg.sender == permittedSender, "sender not golden touch");
        _;
    }

    // This constructor is only used in test as the contract will be pre-deployed in the L2 genesis
    constructor(uint256 _fixedBaseFee, address _permittedSender) {
        require(_fixedBaseFee > 0, "fixedBaseFee must be greater than 0");
        fixedBaseFee = _fixedBaseFee;
        permittedSender = _permittedSender;

        uint256 parentId = block.number - 1;
        blockHashes[parentId] = blockhash(parentId);
        (circularBlocksHash,) = _calcCircularBlocksHash(block.number);
    }

    /// @dev The node software will guarantee and the prover will verify the following:
    /// 1. This function is transacted as the first transaction in the first L2 block derived from the same publication;
    /// 2. This function's gas limit is a fixed value;
    /// 3. This function will not revert.
    /// 4. The parameters correspond to the real L1 state.
    /// @param _publicationId The publication that contains this anchor transaction (as the first transaction)
    /// @param _anchorBlockId The latest L1 block known to the L2 blocks in this publication
    /// @param _anchorBlockHash The block hash of the L1 anchor block
    /// @param _parentGasUsed The gas used in the parent block
    function anchor(uint256 _publicationId, uint256 _anchorBlockId, bytes32 _anchorBlockHash, bytes32 _parentGasUsed)
        external
        onlyFromPermittedSender
    {
        // Make sure this function can only succeed once per publication
        require(_publicationId > lastPublicationId, "publicationId too small");
        lastPublicationId = _publicationId;

        // Make sure L1->L2 sync will use newer block hash
        require(_anchorBlockId >= lastAnchorBlockId, "anchorBlockId too small");
        require(_anchorBlockHash != 0, "anchorBlockHash is 0");

        // Persist anchor block hashes
        if (_anchorBlockId > lastAnchorBlockId) {
            lastAnchorBlockId = _anchorBlockId;
            l1BlockHashes[_anchorBlockId] = _anchorBlockHash;
        }

        // Store the parent block hash in the _blockhashes mapping
        uint256 parentId = block.number - 1;
        blockHashes[parentId] = blockhash(parentId);

        // Calculate the current and new circular hash for the last 255 blocksbased on the parent block ID
        (bytes32 currentHash, bytes32 newHash) = _calcCircularBlocksHash(parentId);
        require(circularBlocksHash == currentHash, "circular hash mismatch");
        circularBlocksHash = newHash;

        _verifyBaseFee(_parentGasUsed);

        emit Anchor(_publicationId, _anchorBlockId, _anchorBlockHash, _parentGasUsed);
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
    function _verifyBaseFee(bytes32 /*_parentGasUsed*/ ) internal view {
        require(block.basefee == fixedBaseFee, "basefee mismatch");
    }
}
