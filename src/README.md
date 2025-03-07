# Contracts

This directory contains the smart contracts for the stack.
The most important contracts are in the `protocol` directory. These are the core contracts and interfaces that are central to the functionality of any rollup that uses the stack.
Contracts in other directories are not part of the core protocol, but still provide useful functionality that most rollups will want to use.

## Project Structure

```
src/
├── blobs/ --> Common registry to store blob references
├── bridges/ --> Bridge implementations for common token standards
├── libs/  --> Utility libraries used by other contracts in this repository or that applications may use
├── protocol/ --> Core contracts and interfaces
│   ├── taiko_alethia/ --> Opinionated implementations for the Taiko Alethia rollup
├── signal/ --> Signal service contracts
├── vendor/ --> Contracts and libraries from other projects that we use
```
