# Gas Optimisation Report: Taiko Inbox Implementation

## Summary

This report attempts to analyse the gas efficiency of Taiko's propose function (`proposeBatch`) and the new implementation of the `publish` function in the minimal rollup inbox. This is meant to serve as a 'point of reference' and is by no means a replacement for more in depth gas analysis (which will be done once we can get real data from running a devnet).

## Methodology

### 1. Repository Setup
- Cloned the Taiko repository at the latest protocol tag: `taiko-alethia-protocol-v2.3.0`
- Extracted the gas report from their test suite
- Set up a comparable testing environment

### 2. Test Configuration

To ensure accurate comparison, we replicated Taiko's testing conditions:

**Taiko's Test Setup:**
- Pre-populates 9 batches before measurement
- Measures gas for 10 subsequent `proposeBatch` calls
- Averages the gas cost across all 10 calls

**Our Test Setup:**
- Pre-populates 9 publications before measurement
- Measures gas for 10 subsequent `publish` calls
- Averages the gas cost across all 10 calls

### 3. Test Implementation Details

#### Taiko's Implementation
The Taiko test (`test_inbox_measure_gas_used`) performs the following:
```solidity
uint64 count = 10;

// Pre-populate 9 batches
WhenMultipleBatchesAreProposedWithDefaultParameters(9)

// Measure 10 proposals
vm.startSnapshotGas("proposeBatch");
uint64[] memory batchIds = _proposeBatchesWithDefaultParameters(count);
uint256 gasProposeBatches = vm.stopSnapshotGas("proposeBatch");
console2.log("Gas per batch - proposing:", gasProposeBatches / count);

function _proposeBatchesWithDefaultParameters(
        uint256 numBatchesToPropose,
        bytes memory txList
    )
        internal
        returns (uint64[] memory batchIds)
    {
        ITaikoInbox.BatchParams memory batchParams;
        batchParams.blocks = new ITaikoInbox.BlockParams[](__blocksPerBatch);

        batchIds = new uint64[](numBatchesToPropose);

        for (uint256 i; i < numBatchesToPropose; ++i) {
            (ITaikoInbox.BatchInfo memory info, ITaikoInbox.BatchMetadata memory meta) =
                inbox.proposeBatch(abi.encode(batchParams), txList);
            _saveMetadataAndInfo(meta, info);
            batchIds[i] = meta.batchId;
        }
    }
```

Each `proposeBatch` call includes:
- Batch parameters with multiple blocks
- Encoded transaction list (abi.encodePacked("txList"))

#### Our Implementation
Our test (`test_gas_TaikoPublishFunction`) mirrors the structure:
```solidity
uint256 numPublications = 10;

// Pre-populate 9 publications
ProposeMultiplePublications(9)

// Measure 10 publications
vm.startSnapshotGas("publish");
_publishMultiplePublications(numPublications);
uint256 publishGas = vm.stopSnapshotGas("publish");
uint256 gasPerPublication = publishGas / numPublications;


function _publishMultiplePublications(uint256 numPublications) internal {
        vm.roll(maxAnchorBlockIdOffset);
        uint256 nBlobs = 1;
        uint64 baseAnchorBlockId = uint64(block.number - 1);

        bytes32[] memory blobHashes = new bytes32[](1);
        blobHashes[0] = keccak256(abi.encodePacked("txList"));

        vm.blobhashes(blobHashes);

        for (uint256 i = 0; i < numPublications; i++) {
            taikoInbox.publish(nBlobs, baseAnchorBlockId);
        }
    }
```

Each `publish` call includes:
- Number of blobs (1)
- Base anchor block ID
- Blob hash commitment

### 4. Gas Measurement Process

Both tests follow the same measurement pattern:
1. Initialise the contract state with preliminary operations
2. Start gas snapshot using foundry vm.snapshot feature
3. Execute 10 operations
4. Stop gas snapshot
5. Calculate average gas per operation

## Results

### Gas Comparison

| Implementation | Gas per Operation | 
|---|---|
| Taiko `proposeBatch` | 654,502 |
| Our `publish` | 44,689 |
| **Absolute Difference** | **609,813** |
| **Percentage Decrease** | **93.17%** |


### Analysis Script

A Python script was developed to automate the comparison (found in scripts/compare_gas.py):
```python
# Extract gas values from both reports
gas_proposing = 654,502    # From test_inbox_measure_gas_used.txt
gas_publication = 44,689   # From minimal_inbox_publish.txt

# Calculate percentage decrease
percentage_decrease = ((gas_proposing - gas_publication) / gas_proposing) * 100
```

## Limitations

- Currently this is only measuring the difference based on imitating the test case. These conditions are quite basic and are not indicative of real-world scenarios (for example the blob/calldata given in the test is minimal compared to that of a real rollup etc.)
- The comparison is not very accurate as taikos current inbox accepts the list of txs as calldata (which will be measured by the gas snapshot) whereas the minimal rollup implementation relies on this information being given as a blob (which is not captured by the gas snapshot). In reality you would need to consider the implication of submitting a blob transaction in addition to the gas consumption of the publish.  

## Conclusion

- This preliminary analysis shows a significant 93.17% gas reduction when using the minimal rollup's `publish` function compared to Taiko's `proposeBatch`. However, these results should be interpreted with caution given the simplified test conditions and different data handling approaches (calldata vs blob transactions). More comprehensive testing on realistic scenarios will be conducted once the minimal rollup infrastructure is deployed to a testnet.

## Future Considerations
- Once the minimal rollup infra can be deployed to a testnet we can re-run these simulations on more realistic rollup test cases to  analyse the gas differences in depth. 
