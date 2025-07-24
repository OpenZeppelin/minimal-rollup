#!/usr/bin/env python3

import re
import sys

TAIKO_GAS_REPORT = "gas-reports/test_inbox_measure_gas_used.txt"
MINIMAL_GAS_REPORT = "gas-reports/taiko_inbox_publish.txt"

def extract_gas_value(file_path, pattern):
    try:
        with open(file_path, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        raise FileNotFoundError(f"File not found: {file_path}")

    match = re.search(pattern, content, re.MULTILINE)
    if not match:
        raise ValueError(f"Pattern not found in {file_path}: {pattern}")
    try:
        return int(match.group(1))
    except (IndexError, ValueError) as e:
        raise ValueError(f"Failed to parse gas value from match: {match.group(0)}")


def calculate_difference(value1, value2):
    diff = value1 - value2
    percentage_decrease = (diff / value1) * 100 if value1 != 0 else 0
    return diff, percentage_decrease


def main():
    pattern1 = r"Gas per proposeBatches:\s*(\d+)"
    pattern2 = r"Gas for publication:\s*(\d+)"
    
    try:
        gas_proposing = extract_gas_value(TAIKO_GAS_REPORT, pattern1)
        gas_publication = extract_gas_value(MINIMAL_GAS_REPORT, pattern2)
        
        abs_diff, percent_decrease = calculate_difference(gas_proposing, gas_publication)
        
        print("Gas Report Comparison")
        print("=" * 50)
        print(f"Gas per proposing (alethia_inbox_proposeV4): {gas_proposing:,}")
        print(f"Gas for publication (minimal_rollup_inbox_publish):       {gas_publication:,}")
        print("=" * 50)
        print(f"Absolute difference: {abs_diff:,}")
        print(f"Percentage decrease: {percent_decrease:.2f}%")
        print()
        
        if percent_decrease > 0:
            print(f"taiko_inbox_publish uses {percent_decrease:.2f}% LESS gas than inbox_without_provermarket")
        elif percent_decrease < 0:
            print(f"taiko_inbox_publish uses {abs(percent_decrease):.2f}% MORE gas than inbox_without_provermarket")
        else:
            print("Both methods use the same amount of gas")

    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
