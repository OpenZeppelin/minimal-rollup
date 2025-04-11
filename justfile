# Start two anvil instances
# "🚨WARNING: This starts two background processes🚨"
# "To stop them, run: just stop-anvil"
start-anvil:
    anvil --port 8545 &
    anvil --port 8546 &
    wait

stop-anvil:
    lsof -ti:8545 | xargs -r kill
    lsof -ti:8546 | xargs -r kill

# Get signal proof for a signal and sender
get-signal-proof signal sender:
    cargo run --bin signal_proof {{signal}} {{sender}}

# Run the storage slot for a signal and sender
get-signal-slot signal sender:
    cargo run --bin signal_slot {{signal}} {{sender}}
