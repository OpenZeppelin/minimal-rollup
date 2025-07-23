#!/bin/bash

# Exit on any error
set -e

# Define variables
REPO_URL="https://github.com/taikoxyz/taiko-mono.git"
TEMP_DIR="taiko-mono-temp"
GAS_REPORT_PATH="packages/protocol/gas-reports/inbox_without_provermarket.txt"
OUTPUT_DIR="output"

echo "Starting gas report extraction..."

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Clone the repository
echo "Cloning repository..."
git clone "$REPO_URL" "$TEMP_DIR"

# Check if the gas report file exists
if [ -f "$TEMP_DIR/$GAS_REPORT_PATH" ]; then
    echo "Found gas report file!"
    # Copy the file to output directory
    cp "$TEMP_DIR/$GAS_REPORT_PATH" "$OUTPUT_DIR/"
    echo "Gas report copied to: $OUTPUT_DIR/inbox_without_provermarket.txt"
else
    echo "Error: Gas report file not found at: $GAS_REPORT_PATH"
    # Clean up and exit with error
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up - remove the cloned repository
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Done! Gas report is available in: $OUTPUT_DIR/inbox_without_provermarket.txt"
