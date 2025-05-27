# Get signal proof for a signal and sender 
get-generic-signal-proof signal sender:
    cargo run --bin generic_signal_proof {{signal}} {{sender}}

get-deposit-signal-proof:
    cargo run --bin deposit_signal_proof

# Get signal slot for a signal and sender
get-signal-slot signal sender:
    cargo run --bin signal_slot {{signal}} {{sender}}

# Create a sample signal proof
create-sample-signal-proof:
    cargo run --bin sample_signal_proof > test/SignalService/SampleProof.t.sol

# Create a sample deposit proof
create-sample-deposit-proof:
    cargo run --bin sample_deposit_proof > test/ETHBridge/SampleDepositProof.t.sol
