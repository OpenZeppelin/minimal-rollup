# Blob Structure

## Context

Blobs can be shared between multiple rollups, as noted in the [Overall Design document](./Overall%20Design.md). The proposed blob structure is guided by the following design goals:

- blob boundaries are not meaningful, but each publication should be contained within a transaction.
- allow proposers to decide per-publication which rollups to include, based on proposal rights and available transactions.
- support any compression algorithm, enabling shared compression for better ratios when multiple rollups use the same algorithm.
- remain minimally opinionated, so rollups can update the structure as desired.


## Existing standards

### Nethermind's proposal

Nethermind's [proposal](https://hackmd.io/@linoscope/blob-sharing-for-based-rollups) is simple but suboptimal for a minimal rollup case because:

- segmentation information is published on L1, increasing L1 requirements.
- rollups sharing a compression algorithm should decompress the publication before splitting it.

### Spire's proposal

Spire has created [this proposal](https://paragraph.xyz/@spire/shared-blob-compression). However, a Merkle tree structure may not be useful because:

- the main advantage of a Merkle tree is to efficiently prove some leaves. In our case we will need each rollup to process the full list of transactions in the publication, so at the very least we should treat each rollup's transactions as one leaf.
- if two rollups share a compression algorithm, both transaction lists will need to be decompressed together (if they want to take advantage of shared compression), so in that case they should also be a single leaf, and we will need an additional mechanism to describe the split within the compressed blob.

It seems a flat structure (which is one of the options they mention) is both simpler and more efficient.

Their proposal also requires registering with the blob aggregation service so it knows which DA layer and compression mechanism to use. Moreover, the rollups are responsible for ensuring the blobs they retrieve out of the aggregation service match the ones that were passed in (using a signature).

The minimal rollup scope only considers Ethereum as the DA layer, avoiding introducing an additional off-chain service. Since the supported compression algorithms are unlikely to change often, rollups may register them on chain so individual L1 proposers can choose their preferred algorithm.

### Dankrad's proposal

Dankrad has created [this proposal](https://ethresear.ch/t/suggested-format-for-shard-blob-header/9996), which is mostly suitable for a minimal rollup with the following modifications:

- identify each supported compression algorithm with an `application_id` as if it were a _format_ identifier
    - Multiple rollups can find and decompress the same compressed data, and a way to split the decompressed data will be required. The suggested approach is using the same segmenting scheme inside the compressed segment
- his post allows for up to 1535 applications per blob. This has some cascading effects:
    - the header is expected to be sorted by application ID, enabling each application to binary search the pointer to the start of the compressed data in the blob
    - if the search fails, either as a result of unsorted data or any other reason, the data is considered unusable. Applications must not reach different conclusions about what data is stored for a given application ID
    - even though publications can span several blobs, it's expected that only a handful of rollups will publish together, perhaps grouped under the same _compression id_ (i.e. `application_id`). Instead of a binary search, a linear search through the whole header can be used to ensure ids are sorted.


## The proposal

With these modifications to Dankrad's proposal, here is a complete description of the suggested design. The description is for how an L2 rollup node must update its state. The corresponding protocol for proposers and provers should follow naturally.

### Preparation

Whoever configures the rollup should publish (perhaps in an on-chain registry) the full list of unique 3-byte data identifiers that the rollup nodes should process. This should include an identifier for:

- its own rollup transactions
- any other rollup transactions it should process (eg. for embedded rollups)
- any other data feeds it should process (eg. for synchrony or coordination)
- any compression (or other data processing) algorithms it supports

### Publication Hashes

The rollup node should find relevant publication hashes in the `PublicationFeed` contract. This will include anything published by its inbox plus any other data feeds that it is watching. There may be multiple relevant publications that share the same blobs, and the rollup node will need to track which blobs it is processing for which reasons. In the simplest case it is just looking for its own rollup transactions inside publications made by its own inbox.

### Publication Headers

For each relevant hash, the publication is the concatenation of all the corresponding blobs. The rollup node should retrieve and validate the first 31-byte chunk, and interpret it as a header with the structure:

- the version (set to zero) (1 byte)
- header length in chunks, excluding this one (1 byte)
    - Most of the times, this field is expected to be `0` since this chunk accommodates 5 segments already; likely enough for most publications.
- multiplier (1 byte)
    - the log base 2 of a scaling factor for data offsets
    - i.e. if this value is $x$ and an offset is specified as $y$, the relevant data starts at chunk $2^x \cdot y$
- Up to 5 data type records consisting of
    - data identifier (3 bytes)
    - offset to corresponding segment after accounting for the multiplier (2 bytes)
- Pad the remaining space with zeroes. Note that zero is an invalid data identifier, so there should be no confusion about what counts as padding.

If the header is larger than one chunk, retrieve and validate the remaining chunks. They should all be structured with the same data type records (up to 6 in a chunk) and padded with zeros.

Although the proposal doesn't rely on binary search, it is still useful to have a deterministic structure. Therefore, in addition to validating the header structure, the rollup nodes should ensure:

- all data identifiers are listed in ascending order
- the actual data segments are also in the same order (i.e. the segment offsets are strictly increasing)
- all segment offsets point within the publication
    - note that the size of a segment is implicitly defined by where the next segment starts.

Assuming the publication header is valid, the rollup node will know which chunks to retrieve and validate to find its relevant segments.


### Compressed segments

The data identifier will indicate which kind of compression (eg. gzip, lz4, etc) was used. After decompression, the segment should use the same structure so that it can be further subdivided. For simplicity:

- the segment header (which has the same format as the publication header) should be outside the compression. This means the expected contents can be identified (and potentially ignored) before retrieving the whole segment and decompressing it.
- Nested compressed segments are discouraged to avoid nodes recursing indefinitely only to find a poorly-formed publication. However, format identifiers are generic enough to represent any kind of data, including the number of compression rounds.

### Rollup segments

After finding and decompressing all relevant segments, the rollup node should process them. The data structure should be defined by the particular use case, with the following recommendations:

- avoid derivable information (such as block hashes or state roots)
- instead, the segment should include the minimum information required to reconstruct the state, which would be something like raw L2 transactions interspersed with block timestamp delimiters.
- pad the rest of the segment with zeros