# Start two anvil instances
start-anvil:
    anvil --port 8545 &
    anvil --port 8546 &
    wait
    echo "🚨WARNING: This starts two background processes🚨"
    echo "To stop them, run: just stop-anvil"

stop-anvil:
    lsof -ti:8545 | xargs -r kill
    lsof -ti:8546 | xargs -r kill

test-int:
    just start-anvil &
    wait
    forge test
    echo "🚨WARNING: This starts two background processes🚨"
    echo "To stop them, run: just stop-anvil"

# Get signal proof 
get-signal-proof signal sender:
    cargo run --bin signal_proof {{signal}} {{sender}}

# Run the storage slot for a signal and sender
get-signal-slot signal sender:
    cargo run --bin signal-slot {{signal}} {{sender}}
