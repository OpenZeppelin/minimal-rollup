# Get signal slot for a signal and sender
get-signal-slot signal sender:
    cargo run --bin signal_slot {{signal}} {{sender}}

# Create a sample signal proof
create-sample-signal-proof:
    cargo run --bin sample_signal_proof > test/SignalService/SampleProof.t.sol

# Create a sample deposit proof
create-sample-deposit-proof:
    cargo run --bin sample_deposit_proof > test/ETHBridge/SampleDepositProof.t.sol
