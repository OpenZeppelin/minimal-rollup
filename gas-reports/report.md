# Gas Optimisation Report: Taiko Inbox Implementation

## Summary

This report analyses the gas efficiency of Taiko's propose function (`proposeBatch`) using real on-chain data and compares it to the new implementation of the `publish` function in the minimal rollup inbox. This analysis serves as a preliminary benchmark, with more comprehensive testing planned once the minimal rollup can be deployed to a testnet. 

## Methodology


### 1. Data Collection Approach

We adopted a hybrid approach combining real-world on-chain data with controlled testing:

**Taiko Data (Real On-chain):**

- Queried Taiko's deployed inbox contract (0x06a9ab27c7e2255df1815e6cc0168d7755feb19a) using Tenderly API
- Analysed the latest ~20 transactions to capture current gas usage patterns
- Filtered specifically for `proposeBatch` method calls
- Verified all transactions used blob storage (EIP-4844) for fair comparison


**Minimal Rollup Data (Test Environment):**

- Implemented a comparable test scenarios using Foundry


### 2. On-chain Data Analysis

Using the Tenderly API, we collected transaction data from Taiko's mainnet deployment:

```python
# API endpoint for Taiko Inbox contract
CONTRACT_ADDRESS = "0x06a9ab27c7e2255df1815e6cc0168d7755feb19a"
url = f"https://api.tenderly.co/api/v1/public-contract/1/address/{CONTRACT_ADDRESS}/explorer/transactions"

```

Key findings from the on-chain analysis:

- All transactions confirmed to use blob storage (`blob_versioned_hashes` present)

- Gas usage was consistent across transactions despite varying blob content
  

Sample transaction data:

```json
{
  "method": "proposeBatch",
  "gas_used": 164334,
  "blob_versioned_hashes": ["0x013d43e92525b7a0d7c6d99937be8d55ed15e2860223ac58f5211e1475a94fbc"],
}
```


### 3. Test Implementation Details


#### Our Testing Setup

To provide a comparison point, we implemented tests that mirror typical rollup operations:


```solidity

uint256 numPublications = 20;

// Pre-populate publications to simulate active rollup state
ProposeMultiplePublications109)

// Measure 10 publications
uint256 numPublications = 20;
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


### 4. Data Processing
  
Python scripts were developed to:

1. Fetch and parse Taiko's on-chain transaction data
2. Filter for `proposeBatch` transactions
3. Calculate average gas consumption
4. Compare with our test results

  
## Results


### Gas Comparison


| Implementation | Gas per Operation | Data Source |
|---|---|---|
| Taiko `proposeBatch` (on-chain) | 181,669 | Real mainnet data (18 txs avg) |
| Our `publish` (test) | 44,563 | Foundry test environment (20 txs avg) |
|  **Absolute Difference**  |  **137,106**  |
|  **Percentage Decrease**  |  **75.47%**  |
  

### On-chain Transaction Analysis
  
From the `proposeBatch` transactions analysed:

- Minimum gas used: 164,334
- Maximum gas used: 182,691
- Average gas used: 18,1669
- Standard deviation: ~18,357


It is worth noting this is somewhat consistent with taikos [gas analysis](https://github.com/taikoxyz/taiko-mono/blob/main/packages/protocol/gas-reports/inbox_without_provermarket.txt) based off foundry. Where the average cost of proposing was ~168,855


## Limitations

### Current Analysis Constraints

1. **Asymmetric Comparison Environment**
- Taiko data: Real on-chain transactions with actual network conditions
- Our data: Clinical test environment with idealised conditions using foundry

2. **Limited Sample Size**
- Only ~20 most recent transactions analysed
- Longer-term patterns and edge cases not captured

## Conclusion

The analysis shows a significant 75.47% gas reduction when using the minimal rollup's `publish` function compared to Taiko's `proposeBatch` based on real on-chain data.


## Next Steps

1. **Testnet Deployment**: Deploy minimal rollup contracts to a testnet for accurate comparison
2. **Extended Analysis**: Collect data over longer periods to capture various network conditions
3. **Load Testing**: Simulate various transaction volumes to identify scaling characteristics

Once the minimal rollup infrastructure is deployed to a testnet, we can conduct a more accurate comparison with both systems operating under identical network conditions.
