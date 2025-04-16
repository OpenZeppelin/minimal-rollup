# Start two anvil instances
# "🚨WARNING: This starts two background processes🚨"
# "To stop them, run: just stop-anvil"
start-anvil:
    # L1 fork
    anvil --port 8545 --chain-id 1 &
    # L2 fork
    anvil --port 8546 --chain-id 2 &
    wait

stop-anvil:
    lsof -ti:8545 | xargs -r kill
    lsof -ti:8546 | xargs -r kill

# Get signal proof for a signal and sender 
get-generic-signal-proof signal sender:
    cargo run --bin generic_signal_proof {{signal}} {{sender}}

get-deposit-signal-proof:
    cargo run --bin deposit_signal_proof

# Get signal slot for a signal, sender and namespace (1: default signal , 2: eth deposit)
get-signal-slot signal sender namespace:
    cargo run --bin signal_slot {{signal}} {{sender}} {{namespace}}
