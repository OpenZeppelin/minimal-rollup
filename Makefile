# Makefile converted from justfile

# Get signal slot for a signal and sender
# Usage: make get-signal-slot signal=<signal> sender=<sender>
get-signal-slot:
	cargo run --bin signal_slot $(signal) $(sender)

# Create a sample signal proof
create-sample-signal-proof:
	cargo run --bin sample_signal_proof > test/SignalService/SampleProof.t.sol

# Create a sample deposit proof
create-sample-deposit-proof:
	cargo run --bin sample_deposit_proof > test/ETHBridge/SampleDepositProof.t.sol

# Compile with forge
compile:
	forge build --build-info --extra-output storage-layout

# Clean build artifacts
clean:
	rm -rf out abis cache* && forge clean

# Default target
.PHONY: get-signal-slot create-sample-signal-proof create-sample-deposit-proof compile clean
