#!/bin/bash

set -e

REPO_URL="https://github.com/taikoxyz/taiko-mono.git"
TAG="taiko-alethia-protocol-v2.3.0"
TEMP_DIR="taiko-mono-temp"
GAS_REPORT_PATH="packages/protocol/deployments/test_inbox_measure_gas_used.txt"
OUTPUT_DIR="gas-reports"

echo "Starting gas report extraction..."

mkdir -p "$OUTPUT_DIR"

echo "Cloning repository..."
git clone --depth 1 --branch "$TAG" "$REPO_URL" "$TEMP_DIR"

# Check if the gas report file exists
if [ -f "$TEMP_DIR/$GAS_REPORT_PATH" ]; then
    echo "Found gas report file!"
    cp "$TEMP_DIR/$GAS_REPORT_PATH" "$OUTPUT_DIR/"
    echo "Gas report copied to: $OUTPUT_DIR/inbox_without_provermarket.txt"
else
    echo "Error: Gas report file not found at: $GAS_REPORT_PATH"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Done! Gas report is available in: $OUTPUT_DIR/inbox_without_provermarket.txt"
