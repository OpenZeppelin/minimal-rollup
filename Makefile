
.PHONY: anvil-nodes

anvil-nodes:
	@echo "Starting Anvil nodes on ports 8545 and 8546..."
	@bash -c '\
		anvil --port 8545 & \
		PID1=$$!; \
		anvil --port 8546 & \
		PID2=$$!; \
		echo "Anvil running. Press Ctrl+C to stop."; \
		trap "kill $$PID1 $$PID2" SIGINT SIGTERM; \
		wait'
